$script:buildOptionsTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'BuildOptions.TestSupport.ps1')).Path
$global:buildOptionsTestSupportFunctionNameList = @(
    'New-TestProjectRoot'
    'Write-TestProjectJson'
    'Get-BuiltModuleFilePath'
    'Invoke-TestProjectBuild'
    'Get-BuiltModuleContent'
    'Invoke-BuildAndParsePsm1Ast'
    'Get-TestProjectInfoValue'
    'New-TestProjectWithNestedSourceFiles'
    'Get-NestedSourceBuildSummary'
    'New-TestProjectWithDuplicateFunctions'
    'Assert-InvokeNovaBuildThrows'
    'Get-TopLevelFunctionAstFromAst'
    'Write-TestMarkerPesterFile'
    'Invoke-TestProjectTests'
    'New-TestProjectWithResources'
    'New-TestProjectWithMarkerTests'
)

. $script:buildOptionsTestSupportPath

foreach ($functionName in $global:buildOptionsTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $buildOptionsTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'BuildOptions.TestSupport.ps1')).Path
    $buildOptionsTestSupportFunctionNameList = $global:buildOptionsTestSupportFunctionNameList

    . $buildOptionsTestSupportPath

    foreach ($functionName in $buildOptionsTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    $distModuleDir = Join-Path $repoRoot "dist/$moduleName"
    if (-not (Test-Path -LiteralPath $distModuleDir)) {
        throw "Expected built $moduleName module at: $distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $moduleName -ErrorAction SilentlyContinue
    Import-Module $distModuleDir -Force
}

Describe 'Invoke-NovaBuild options' {

    It 'project template can omit CopyResourcesToModuleRoot because the default is false' {
        $template = Get-Content -LiteralPath (Join-Path $repoRoot 'src/resources/ProjectTemplate.json') -Raw | ConvertFrom-Json

        $template.PSObject.Properties.Name | Should -Not -Contain 'CopyResourcesToModuleRoot'
    }

    It 'example project shows CopyResourcesToModuleRoot explicitly for discoverability' {
        $example = Get-Content -LiteralPath (Join-Path $repoRoot 'example/project.json') -Raw | ConvertFrom-Json

        $example.PSObject.Properties.Name | Should -Contain 'CopyResourcesToModuleRoot'
        $example.CopyResourcesToModuleRoot | Should -BeFalse
    }

    It 'example project builds and tests successfully as a working reference project' {
        $exampleRoot = Join-Path $repoRoot 'example'
        $result = Invoke-TestProjectTests -ProjectRoot $exampleRoot -ModulePath $distModuleDir
        $exampleProject = Get-Content -LiteralPath (Join-Path $exampleRoot 'project.json') -Raw | ConvertFrom-Json
        $builtModulePath = Join-Path $exampleRoot ("dist/{0}/{0}.psm1" -f $exampleProject.ProjectName)

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        (Test-Path -LiteralPath $builtModulePath) | Should -BeTrue
    }

    It 'BuildRecursiveFolders=false excludes nested classes/private and nested public' {
        $root = New-TestProjectWithNestedSourceFiles -TestDriveRoot $TestDrive -Name 'NoRecurse' -Options @{ ProjectName = 'NoRecurse'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $false }
        $summary = Get-NestedSourceBuildSummary -ProjectRoot $root

        $summary.TypeNames | Should -Not -Contain 'NestedThing'
        $summary.FunctionNames | Should -Not -Contain 'Invoke-NestedPrivateA'
        $summary.FunctionNames | Should -Not -Contain 'Invoke-NestedPublic'
    }

    It 'BuildRecursiveFolders=true includes nested classes/private but never nested public' {
        $root = New-TestProjectWithNestedSourceFiles -TestDriveRoot $TestDrive -Name 'Recurse' -Options @{ ProjectName = 'Recurse'; BuildRecursiveFolders = $true; FailOnDuplicateFunctionNames = $false } -IncludeTopLevelFiles
        $summary = Get-NestedSourceBuildSummary -ProjectRoot $root

        $summary.TypeNames | Should -Contain 'NestedThing'
        $summary.FunctionNames | Should -Contain 'Invoke-NestedPrivateA'
        $summary.FunctionNames | Should -Contain 'Invoke-PublicTop'
        $summary.FunctionNames | Should -Contain 'Invoke-PrivateTop'
        $summary.FunctionNames | Should -Not -Contain 'Invoke-NestedPublic'

        $classOffset = ($summary.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst] -and $n.Name -eq 'NestedThing' }, $true) | Select-Object -First 1).Extent.StartOffset
        $publicOffset = ($summary.FunctionAsts | Where-Object Name -eq 'Invoke-PublicTop' | Select-Object -First 1).Extent.StartOffset
        $privateOffset = ($summary.FunctionAsts | Where-Object Name -eq 'Invoke-PrivateTop' | Select-Object -First 1).Extent.StartOffset

        $classOffset | Should -BeLessThan $publicOffset
        $publicOffset | Should -BeLessThan $privateOffset

        # Deterministic sort within private: a/* comes before b/*
        Set-Content -LiteralPath (Join-Path $root 'src/private/b/PrivateB.ps1') -Value 'function Invoke-NestedPrivateB { }' -Encoding utf8
        $summary2 = Get-NestedSourceBuildSummary -ProjectRoot $root
        $aOffset = ($summary2.FunctionAsts | Where-Object Name -eq 'Invoke-NestedPrivateA' | Select-Object -First 1).Extent.StartOffset
        $bOffset = ($summary2.FunctionAsts | Where-Object Name -eq 'Invoke-NestedPrivateB' | Select-Object -First 1).Extent.StartOffset
        $aOffset | Should -BeLessThan $bOffset
    }

    It 'missing BuildRecursiveFolders defaults to true for classes/private but never nested public' {
        $root = New-TestProjectWithNestedSourceFiles -TestDriveRoot $TestDrive -Name 'RecurseDefault' -Options @{ ProjectName = 'RecurseDefault'; SetSourcePath = $false; FailOnDuplicateFunctionNames = $false }

        (Get-TestProjectInfoValue -ProjectRoot $root -PropertyName 'BuildRecursiveFolders') | Should -BeTrue

        $summary = Get-NestedSourceBuildSummary -ProjectRoot $root
        $summary.TypeNames | Should -Contain 'NestedThing'
        $summary.FunctionNames | Should -Contain 'Invoke-NestedPrivateA'
        $summary.FunctionNames | Should -Not -Contain 'Invoke-NestedPublic'
    }


    It 'missing SetSourcePath defaults to true and emits source markers' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'SetSourceDefault'
        Write-TestProjectJson -ProjectRoot $root -Options @{ ProjectName = 'SetSourceDefault'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $false }

        [System.IO.File]::WriteAllText((Join-Path $root 'src/public/PublicTop.ps1'), 'function Invoke-PublicTop { }')

        Push-Location -LiteralPath $root
        try {
            (Get-NovaProjectInfo).SetSourcePath | Should -BeTrue
        }
        finally {
            Pop-Location
        }

        $content = Get-BuiltModuleContent -ProjectRoot $root
        $content | Should -Match '(?m)^# Source: src/public/PublicTop.ps1$'
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

    It 'CopyResourcesToModuleRoot=true copies resource content directly into the built module root' {
        $project = New-TestProjectWithResources -TestDriveRoot $TestDrive -Name 'ResourceToRoot' -CopyResourcesToModuleRoot $true

        (Test-Path -LiteralPath (Join-Path $project.ModuleDir 'config.json')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $project.ModuleDir 'nested/child.txt')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $project.ModuleDir 'resources')) | Should -BeFalse
    }

    It 'CopyResourcesToModuleRoot=false keeps resources inside a resources folder in the built module' {
        $project = New-TestProjectWithResources -TestDriveRoot $TestDrive -Name 'ResourceToFolder' -CopyResourcesToModuleRoot $false

        (Test-Path -LiteralPath (Join-Path $project.ModuleDir 'resources/config.json')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $project.ModuleDir 'resources/nested/child.txt')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $project.ModuleDir 'config.json')) | Should -BeFalse
    }

    Context 'Test-NovaBuild discovery for BuildRecursiveFolders=<BuildRecursiveFolders>' -ForEach @(
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

    It 'missing FailOnDuplicateFunctionNames defaults to true and fails on duplicate top-level function names' {
        $root = New-TestProjectWithDuplicateFunctions -TestDriveRoot $TestDrive -Name 'DupDefault' -Options @{ ProjectName = 'DupDefault'; BuildRecursiveFolders = $false; SetSourcePath = $false }

        (Get-TestProjectInfoValue -ProjectRoot $root -PropertyName 'FailOnDuplicateFunctionNames') | Should -BeTrue
        Assert-InvokeNovaBuildThrows -ProjectRoot $root
    }

    It 'fails build when Manifest contains unsupported New-ModuleManifest parameters' {
        $root = New-TestProjectRoot -TestDriveRoot $TestDrive -Name 'BadManifestParameter'
        Write-TestProjectJson -ProjectRoot $root -Options @{ProjectName = 'BadManifestParameter'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $false}
        Set-Content -LiteralPath (Join-Path $root 'src/public/PublicTop.ps1') -Value 'function Invoke-PublicTop { }' -Encoding utf8

        $projectJsonPath = Join-Path $root 'project.json'
        $project = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
        $project.Manifest['BogusKey'] = 'nope'
        $project | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        {
            Push-Location -LiteralPath $root
            try {
                Invoke-NovaBuild
            }
            finally {
                Pop-Location
            }
        } | Should -Throw 'Unknown parameter(s) in Manifest: BogusKey'
    }

    It 'FailOnDuplicateFunctionNames=true fails when built psm1 contains duplicate top-level function names' {
        $root = New-TestProjectWithDuplicateFunctions -TestDriveRoot $TestDrive -Name 'DupFail' -Options @{ ProjectName = 'DupFail'; BuildRecursiveFolders = $false; FailOnDuplicateFunctionNames = $true }
        Assert-InvokeNovaBuildThrows -ProjectRoot $root
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
