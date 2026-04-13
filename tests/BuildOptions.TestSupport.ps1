function New-TestProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestDriveRoot,
        [Parameter(Mandatory)][string]$Name
    )

    $root = Join-Path $TestDriveRoot $Name
    New-Item -ItemType Directory -Path $root -Force | Out-Null

    foreach ($dir in @(
            'src/public',
            'src/public/nested',
            'src/private',
            'src/private/a',
            'src/private/b',
            'src/classes',
            'src/classes/nested',
            'tests',
            'tests/nested',
            'docs'
        )) {
        New-Item -ItemType Directory -Path (Join-Path $root $dir) -Force | Out-Null
    }

    return $root
}

function Write-TestProjectJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][hashtable]$Options
    )

    $project = [ordered]@{
        ProjectName = ('' + $Options.ProjectName)
        Description = 'Test project'
        Version = '0.0.1'
        copyResourcesToModuleRoot = $false
        Manifest = [ordered]@{
            Author = 'Test'
            PowerShellHostVersion = '7.4'
            GUID = '11111111-1111-1111-1111-111111111111'
            Tags = @()
            ProjectUri = ''
        }
        Pester = [ordered]@{
            TestResult = [ordered]@{
                Enabled = $true
                OutputFormat = 'NUnitXml'
            }
            Output = [ordered]@{
                Verbosity = 'Detailed'
            }
        }
    }

    if ($Options.ContainsKey('BuildRecursiveFolders')) {
        $project.BuildRecursiveFolders = [bool]$Options.BuildRecursiveFolders
    }

    if ($Options.ContainsKey('SetSourcePath')) {
        $project.SetSourcePath = [bool]$Options.SetSourcePath
    }

    if ($Options.ContainsKey('FailOnDuplicateFunctionNames')) {
        $project.FailOnDuplicateFunctionNames = [bool]$Options.FailOnDuplicateFunctionNames
    }

    if ( $Options.ContainsKey('Preamble')) {
        $project.Preamble = $Options.Preamble
    }

    if ( $Options.ContainsKey('copyResourcesToModuleRoot')) {
        $project.copyResourcesToModuleRoot = [bool]$Options.copyResourcesToModuleRoot
    }

    $json = $project | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath (Join-Path $ProjectRoot 'project.json') -Value $json -Encoding utf8
}

function Get-BuiltModuleFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    Push-Location -LiteralPath $ProjectRoot
    try {
        $info = Get-NovaProjectInfo
        return (Join-Path $ProjectRoot ("dist/{0}/{0}.psm1" -f $info.ProjectName))
    }
    finally {
        Pop-Location
    }
}

function Invoke-TestProjectBuild {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    Push-Location -LiteralPath $ProjectRoot
    try {
        Invoke-NovaBuild
        $psm1 = Get-BuiltModuleFilePath -ProjectRoot $ProjectRoot
        if (-not (Test-Path -LiteralPath $psm1)) {
            throw "Expected built psm1 not found: $psm1"
        }

        return $psm1
    }
    finally {
        Pop-Location
    }
}

function Get-BuiltModuleContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $psm1 = Invoke-TestProjectBuild -ProjectRoot $ProjectRoot
    return [IO.File]::ReadAllText($psm1)
}

function Invoke-BuildAndParsePsm1Ast {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $psm1 = Invoke-TestProjectBuild -ProjectRoot $ProjectRoot
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($psm1, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        throw "Built psm1 parse errors: $(@($errors | ForEach-Object Message) -join '; ')"
    }

    return $ast
}

function Get-TestProjectInfoValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$PropertyName
    )

    Push-Location -LiteralPath $ProjectRoot
    try {
        return (Get-NovaProjectInfo).$PropertyName
    }
    finally {
        Pop-Location
    }
}

function New-TestProjectWithNestedSourceFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestDriveRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][hashtable]$Options,
        [switch]$IncludeTopLevelFiles
    )

    $root = New-TestProjectRoot -TestDriveRoot $TestDriveRoot -Name $Name
    Write-TestProjectJson -ProjectRoot $root -Options $Options

    Set-Content -LiteralPath (Join-Path $root 'src/classes/nested/Thing.ps1') -Value 'class NestedThing { [string]$Name }' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $root 'src/private/a/PrivateA.ps1') -Value 'function Invoke-NestedPrivateA { }' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $root 'src/public/nested/PublicNested.ps1') -Value 'function Invoke-NestedPublic { }' -Encoding utf8

    if ($IncludeTopLevelFiles) {
        Set-Content -LiteralPath (Join-Path $root 'src/public/PublicTop.ps1') -Value 'function Invoke-PublicTop { }' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $root 'src/private/PrivateTop.ps1') -Value 'function Invoke-PrivateTop { }' -Encoding utf8
    }

    return $root
}

function Get-NestedSourceBuildSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $ast = Invoke-BuildAndParsePsm1Ast -ProjectRoot $ProjectRoot
    $functionAsts = @(Get-TopLevelFunctionAstFromAst -Ast $ast)

    return [pscustomobject]@{
        Ast = $ast
        TypeNames = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.TypeDefinitionAst] }, $true) | ForEach-Object Name)
        FunctionAsts = $functionAsts
        FunctionNames = @($functionAsts | ForEach-Object Name)
    }
}

function New-TestProjectWithDuplicateFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestDriveRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][hashtable]$Options
    )

    $root = New-TestProjectRoot -TestDriveRoot $TestDriveRoot -Name $Name
    Write-TestProjectJson -ProjectRoot $root -Options $Options
    Set-Content -LiteralPath (Join-Path $root 'src/public/Dup.ps1') -Value 'function Invoke-Dup { }' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $root 'src/private/Dup.ps1') -Value 'function Invoke-Dup { }' -Encoding utf8
    return $root
}

function Assert-InvokeNovaBuildThrows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [string]$ExpectedMessage
    )

    $scriptBlock = {
        Push-Location -LiteralPath $ProjectRoot
        try {
            Invoke-NovaBuild
        }
        finally {
            Pop-Location
        }
    }

    if ( [string]::IsNullOrWhiteSpace($ExpectedMessage)) {
        $scriptBlock | Should -Throw
        return
    }

    $scriptBlock | Should -Throw $ExpectedMessage
}

function Get-InvokeNovaBuildErrorMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    Push-Location -LiteralPath $ProjectRoot
    try {
        try {
            Invoke-NovaBuild
        }
        catch {
            return $_.Exception.Message
        }
    }
    finally {
        Pop-Location
    }

    throw 'Expected Invoke-NovaBuild to throw, but it succeeded.'
}

function Get-TopLevelFunctionAstFromAst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.Language.Ast]$Ast
    )

    $all = @($Ast.FindAll({
                param($n)
                $n -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true))

    $top = foreach ($candidate in $all) {
        $nested = $false
        foreach ($other in $all) {
            if ($other -eq $candidate) { continue }

            if ($other.Extent.StartOffset -lt $candidate.Extent.StartOffset -and $other.Extent.EndOffset -gt $candidate.Extent.EndOffset) {
                $nested = $true
                break
            }
        }

        if (-not $nested) { $candidate }
    }

    return @($top)
}

function Write-TestMarkerPesterFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][pscustomobject]$TestCase
    )

    $content = @"
Describe '$($TestCase.Name)' {
    It 'imports built module and writes marker' {
        Import-Module '$($TestCase.BuiltModulePath)' -Force
        Get-Module -Name '$($TestCase.ProjectName)' | Should -Not -BeNullOrEmpty
        Set-Content -LiteralPath '$($TestCase.MarkerPath)' -Value '$($TestCase.Name)' -Encoding utf8 -NoNewline
        (Get-Content -LiteralPath '$($TestCase.MarkerPath)' -Raw) | Should -Be '$($TestCase.Name)'
    }
}
"@

    Set-Content -LiteralPath $FilePath -Value $content -Encoding utf8
}

function Invoke-TestProjectTests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ModulePath
    )

    $scriptPath = Join-Path $ProjectRoot 'Run-TestNovaBuild.ps1'
    $script = @"
`$ErrorActionPreference = 'Stop'
Import-Module '$ModulePath' -Force
Set-Location -LiteralPath '$ProjectRoot'
Invoke-NovaBuild
Test-NovaBuild
"@

    Set-Content -LiteralPath $scriptPath -Value $script -Encoding utf8

    try {
        $output = & pwsh -NoLogo -NoProfile -File $scriptPath 2>&1
        [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = @($output)
        }
    }
    finally {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

function New-TestProjectWithResources {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestDriveRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$CopyResourcesToModuleRoot
    )

    $root = New-TestProjectRoot -TestDriveRoot $TestDriveRoot -Name $Name
    Write-TestProjectJson -ProjectRoot $root -Options @{
        ProjectName = $Name
        BuildRecursiveFolders = $false
        FailOnDuplicateFunctionNames = $false
        copyResourcesToModuleRoot = $CopyResourcesToModuleRoot
    }

    New-Item -ItemType Directory -Path (Join-Path $root 'src/resources/nested') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $root 'src/public/PublicTop.ps1') -Value 'function Invoke-PublicTop { }' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $root 'src/resources/config.json') -Value '{"key":"value"}' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $root 'src/resources/nested/child.txt') -Value 'child' -Encoding utf8

    $psm1 = Invoke-TestProjectBuild -ProjectRoot $root
    return [pscustomobject]@{
        Root = $root
        ModuleDir = Split-Path -Parent $psm1
    }
}

function New-TestProjectWithMarkerTests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestDriveRoot,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][bool]$BuildRecursiveFolders
    )

    $root = New-TestProjectRoot -TestDriveRoot $TestDriveRoot -Name $Name
    $projectName = $Name

    Write-TestProjectJson -ProjectRoot $root -Options @{
        ProjectName = $projectName
        BuildRecursiveFolders = $BuildRecursiveFolders
        FailOnDuplicateFunctionNames = $false
    }

    Set-Content -LiteralPath (Join-Path $root 'src/public/PublicTop.ps1') -Value 'function Invoke-PublicTop { }' -Encoding utf8

    $topMarker = Join-Path $root 'top-level-ran.txt'
    $nestedMarker = Join-Path $root 'nested-ran.txt'
    $builtModulePath = Join-Path $root ("dist/{0}/{0}.psm1" -f $projectName)

    $topLevelTest = [pscustomobject]@{
        Name = 'TopLevel'
        MarkerPath = $topMarker
        ProjectName = $projectName
        BuiltModulePath = $builtModulePath
    }
    $nestedTest = [pscustomobject]@{
        Name = 'Nested'
        MarkerPath = $nestedMarker
        ProjectName = $projectName
        BuiltModulePath = $builtModulePath
    }

    Write-TestMarkerPesterFile -FilePath (Join-Path $root 'tests/TopLevel.Tests.ps1') -TestCase $topLevelTest
    Write-TestMarkerPesterFile -FilePath (Join-Path $root 'tests/nested/Nested.Tests.ps1') -TestCase $nestedTest

    [pscustomobject]@{
        Root = $root
        TopMarker = $topMarker
        NestedMarker = $nestedMarker
    }
}

function New-TestProjectWithPreamble {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestDriveRoot,
        [Parameter(Mandatory)][string]$Name,
        [hashtable]$Options = @{}
    )

    $projectOptions = @{
        ProjectName = $Name
        BuildRecursiveFolders = [bool]$Options.IncludeClassAndPrivate
        SetSourcePath = [bool]$Options.SetSourcePath
        FailOnDuplicateFunctionNames = $false
    }
    if ( $Options.ContainsKey('Preamble')) {
        $projectOptions.Preamble = $Options.Preamble
    }

    $root = New-TestProjectRoot -TestDriveRoot $TestDriveRoot -Name $Name
    Write-TestProjectJson -ProjectRoot $root -Options $projectOptions

    Set-Content -LiteralPath (Join-Path $root 'src/public/PublicTop.ps1') -Value 'function Invoke-PublicTop { "public" }' -Encoding utf8
    if (-not $projectOptions.BuildRecursiveFolders) {
        return $root
    }

    Set-Content -LiteralPath (Join-Path $root 'src/classes/nested/Thing.ps1') -Value 'class NestedThing { [string]$Name }' -Encoding utf8
    Set-Content -LiteralPath (Join-Path $root 'src/private/a/PrivateA.ps1') -Value 'function Invoke-PrivateA { "private" }' -Encoding utf8
    return $root
}

