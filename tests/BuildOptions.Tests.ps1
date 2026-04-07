BeforeAll {
    . (Join-Path $PSScriptRoot 'BuildOptions.TestSupport.ps1')

    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here

    $distModuleDir = Join-Path $repoRoot 'dist/ModuleTools'
    if (-not (Test-Path -LiteralPath $distModuleDir)) {
        throw "Expected built ModuleTools module at: $distModuleDir. Run Invoke-MTBuild in the repo root first."
    }

    Remove-Module ModuleTools -ErrorAction SilentlyContinue
    Import-Module $distModuleDir -Force
}

Describe 'Invoke-MTBuild options' {
    It 'BuildRecursiveFolders=false excludes nested classes/private and nested public' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'NoRecurse'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'NoRecurse'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $false }

        Set-Content -LiteralPath (Join-Path $root 'src/classes/nested/Thing.ps1') -Value 'class NestedThing { [string]$Name }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/private/a/PrivateA.ps1') -Value 'function Invoke-NestedPrivateA { }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/public/nested/PublicNested.ps1') -Value 'function Invoke-NestedPublic { }' -Encoding utf8

        $ast = Invoke-BuildAndParsePsm1Ast -ProjectRoot $root

        $typeNames = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true) | ForEach-Object Name)
        $typeNames | Should -Not -Contain 'NestedThing'

        $fnNames = @(Get-TopLevelFunctionAstFromAst -Ast $ast | ForEach-Object Name)
        $fnNames | Should -Not -Contain 'Invoke-NestedPrivateA'
        $fnNames | Should -Not -Contain 'Invoke-NestedPublic'
    }

    It 'BuildRecursiveFolders=true includes nested classes/private but never nested public' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'Recurse'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'Recurse'; BuildRecursiveFolders = $true; FailOnDuplicateFunctionNames = $false }

        Set-Content -LiteralPath (Join-Path $root 'src/classes/nested/Thing.ps1') -Value 'class NestedThing { [string]$Name }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/private/a/PrivateA.ps1') -Value 'function Invoke-NestedPrivateA { }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/public/nested/PublicNested.ps1') -Value 'function Invoke-NestedPublic { }' -Encoding utf8

        Set-Content -LiteralPath (Join-Path $root 'src/public/PublicTop.ps1') -Value 'function Invoke-PublicTop { }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/private/PrivateTop.ps1') -Value 'function Invoke-PrivateTop { }' -Encoding utf8

        $ast = Invoke-BuildAndParsePsm1Ast -ProjectRoot $root

        $typeNames = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true) | ForEach-Object Name)
        $typeNames | Should -Contain 'NestedThing'

        $fn = @(Get-TopLevelFunctionAstFromAst -Ast $ast)
        $fnNames = @($fn | ForEach-Object Name)

        $fnNames | Should -Contain 'Invoke-NestedPrivateA'
        $fnNames | Should -Contain 'Invoke-PublicTop'
        $fnNames | Should -Contain 'Invoke-PrivateTop'
        $fnNames | Should -Not -Contain 'Invoke-NestedPublic'

        $classOffset = ($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst] -and $n.Name -eq 'NestedThing' }, $true) | Select-Object -First 1).Extent.StartOffset
        $publicOffset = ($fn | Where-Object Name -eq 'Invoke-PublicTop' | Select-Object -First 1).Extent.StartOffset
        $privateOffset = ($fn | Where-Object Name -eq 'Invoke-PrivateTop' | Select-Object -First 1).Extent.StartOffset

        $classOffset | Should -BeLessThan $publicOffset
        $publicOffset | Should -BeLessThan $privateOffset

        # Deterministic sort within private: a/* comes before b/*
        Set-Content -LiteralPath (Join-Path $root 'src/private/b/PrivateB.ps1') -Value 'function Invoke-NestedPrivateB { }' -Encoding utf8
        $ast2 = Invoke-BuildAndParsePsm1Ast -ProjectRoot $root
        $fn2 = @(Get-TopLevelFunctionAstFromAst -Ast $ast2)
        $aOffset = ($fn2 | Where-Object Name -eq 'Invoke-NestedPrivateA' | Select-Object -First 1).Extent.StartOffset
        $bOffset = ($fn2 | Where-Object Name -eq 'Invoke-NestedPrivateB' | Select-Object -First 1).Extent.StartOffset
        $aOffset | Should -BeLessThan $bOffset
    }


    It 'missing SetSourcePath defaults to false and emits no source markers' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'SetSourceDefault'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'SetSourceDefault'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $false }

        [System.IO.File]::WriteAllText((Join-Path $root 'src/public/PublicTop.ps1'), 'function Invoke-PublicTop { }')

        Push-Location -LiteralPath $root
        try {
            (Get-MTProjectInfo).SetSourcePath | Should -BeFalse
        }
        finally {
            Pop-Location
        }

        $content = Get-BuiltModuleContent -ProjectRoot $root
        $content | Should -Not -Match '(?m)^# Source: '
    }

    It 'SetSourcePath=false preserves current concatenation output exactly' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'SetSourceOff'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'SetSourceOff'; BuildRecursiveFolders = $false; SetSourcePath = $false; FailOnDuplicateFunctionNames = $false }

        [System.IO.File]::WriteAllText((Join-Path $root 'src/classes/Strict.ps1'), 'Set-StrictMode -Version Latest')
        [System.IO.File]::WriteAllText((Join-Path $root 'src/public/PublicTop.ps1'), 'function Invoke-PublicTop { "public" }')
        [System.IO.File]::WriteAllText((Join-Path $root 'src/private/PrivateTop.ps1'), 'function Invoke-PrivateTop { "private" }')

        $newLine = [Environment]::NewLine
        $expected = @(
            'Set-StrictMode -Version Latest',
            'function Invoke-PublicTop { "public" }',
            'function Invoke-PrivateTop { "private" }'
        ) -join ($newLine + $newLine)

        $content = Get-BuiltModuleContent -ProjectRoot $root
        $content | Should -Be ($expected + $newLine + $newLine + $newLine)
    }

    It 'SetSourcePath=true writes one normalized relative source marker before each file and keeps the module importable' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'SetSourceOn'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'SetSourceOn'; BuildRecursiveFolders = $true; SetSourcePath = $true; FailOnDuplicateFunctionNames = $false }

        [System.IO.File]::WriteAllText((Join-Path $root 'src/classes/nested/Thing.ps1'), 'class NestedThing { [string]$Name }')
        [System.IO.File]::WriteAllText((Join-Path $root 'src/public/PublicTop.ps1'), 'function Invoke-PublicTop { "public" }')
        [System.IO.File]::WriteAllText((Join-Path $root 'src/private/a/PrivateA.ps1'), 'function Invoke-PrivateA { "private" }')

        $psm1 = Invoke-TestProjectBuild -ProjectRoot $root
        $content = [System.IO.File]::ReadAllText($psm1)
        $newLine = [Environment]::NewLine

        ([regex]::Matches($content, '(?m)^# Source: .+$')).Count | Should -Be 3
        $content | Should -Not -Match '\\'

        $classBlock = "# Source: src/classes/nested/Thing.ps1${newLine}class NestedThing { [string]`$Name }"
        $publicBlock = "# Source: src/public/PublicTop.ps1${newLine}function Invoke-PublicTop { `"public`" }"
        $privateBlock = "# Source: src/private/a/PrivateA.ps1${newLine}function Invoke-PrivateA { `"private`" }"

        $content.Contains($classBlock) | Should -BeTrue
        $content.Contains($publicBlock) | Should -BeTrue
        $content.Contains($privateBlock) | Should -BeTrue

        $classIndex = $content.IndexOf('# Source: src/classes/nested/Thing.ps1')
        $publicIndex = $content.IndexOf('# Source: src/public/PublicTop.ps1')
        $privateIndex = $content.IndexOf('# Source: src/private/a/PrivateA.ps1')

        $classIndex | Should -BeGreaterThan -1
        $publicIndex | Should -BeGreaterThan -1
        $privateIndex | Should -BeGreaterThan -1
        $classIndex | Should -BeLessThan $publicIndex
        $publicIndex | Should -BeLessThan $privateIndex

        Remove-Module SetSourceOn -ErrorAction SilentlyContinue
        { Import-Module (Split-Path -Parent $psm1) -Force -ErrorAction Stop } | Should -Not -Throw
        Get-Command Invoke-PublicTop -Module SetSourceOn | Should -Not -BeNullOrEmpty
        Remove-Module SetSourceOn -ErrorAction SilentlyContinue
    }
    Context 'Invoke-MTTest discovery for BuildRecursiveFolders=<BuildRecursiveFolders>' -ForEach @(
        @{ Name = 'TestsTopOnly'; BuildRecursiveFolders = $false; ExpectedNestedMarker = $false }
        @{ Name = 'TestsRecursive'; BuildRecursiveFolders = $true; ExpectedNestedMarker = $true }
    ) {
        It 'runs the expected set of top-level and nested tests' {
            $project = New-TestProjectWithMarkerTests -TestDriveRoot $TestDrive -Name $_.Name -BuildRecursiveFolders $_.BuildRecursiveFolders
            $result = Invoke-TestProjectTests -ProjectRoot $project.Root -ModulePath $distModuleDir

            $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
            (Test-Path -LiteralPath $project.TopMarker) | Should -BeTrue
            (Test-Path -LiteralPath $project.NestedMarker) | Should -Be $_.ExpectedNestedMarker
        }
    }

    It 'FailOnDuplicateFunctionNames=true fails when built psm1 contains duplicate top-level function names' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'DupFail'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'DupFail'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $true }

        Set-Content -LiteralPath (Join-Path $root 'src/public/Dup.ps1') -Value 'function Invoke-Dup { }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/private/Dup.ps1') -Value 'function Invoke-Dup { }' -Encoding utf8

        {
            Push-Location -LiteralPath $root
            try {
                Invoke-MTBuild
            }
            finally {
                Pop-Location
            }
        } | Should -Throw
    }

    It 'FailOnDuplicateFunctionNames=false allows duplicates (last wins) for backward compatibility' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'DupAllowed'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'DupAllowed'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $false }

        Set-Content -LiteralPath (Join-Path $root 'src/public/Dup.ps1') -Value 'function Invoke-Dup { "first" }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/private/Dup.ps1') -Value 'function Invoke-Dup { "second" }' -Encoding utf8

        $ast = Invoke-BuildAndParsePsm1Ast -ProjectRoot $root
        $fnNames = @(Get-TopLevelFunctionAstFromAst -Ast $ast | ForEach-Object Name)
        $fnNames | Should -Contain 'Invoke-Dup'
    }
}
