param(
    [string]$OutputDirectory = './artifacts',
    [string[]]$ExcludeTag = @()
)

Set-StrictMode -Version Latest

function Copy-NovaModuleToolsArtifactIfPresent {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath
    )

    if (Test-Path -LiteralPath $SourcePath) {
        Copy-Item -LiteralPath $SourcePath -Destination $DestinationPath -Force
    }
}

function ConvertTo-NovaSingleQuotedPowerShellLiteral {
    param(
        [Parameter(Mandatory)][string]$Value
    )

    return "'$($Value.Replace("'", "''") )'"
}

function Get-NovaModuleToolsValidationCommand {
    param(
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$CommandName,
        [string[]]$ExcludeTag = @()
    )

    $commandLine = $CommandName
    if (@($ExcludeTag).Count -gt 0) {
        $excludeTagLiteral = @($ExcludeTag | ForEach-Object {ConvertTo-NovaSingleQuotedPowerShellLiteral -Value ([string]$_)}) -join ', '
        $commandLine += " -ExcludeTagFilter @($excludeTagLiteral)"
    }

    return "Import-Module $( ConvertTo-NovaSingleQuotedPowerShellLiteral -Value $BuiltModulePath ) -Force -ErrorAction Stop; $commandLine"
}

function Invoke-NovaModuleToolsFreshValidationCommand {
    param(
        [Parameter(Mandatory)][string]$Command
    )

    & pwsh -NoLogo -NoProfile -Command $Command
    if ($LASTEXITCODE -ne 0) {
        throw "Validation command failed: $Command"
    }
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..' '..')).Path
Set-Location $repoRoot
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Import-Module NovaModuleTools -ErrorAction Stop

$projectInfo = Get-NovaProjectInfo
Invoke-NovaBuild
$builtModulePath = Join-Path $projectInfo.OutputModuleDir "$( $projectInfo.ProjectName ).psd1"

$novaModuleToolsTestFailed = $false
try {
    $unitTestCommand = Get-NovaModuleToolsValidationCommand -BuiltModulePath $builtModulePath -CommandName 'Invoke-NovaTest' -ExcludeTag $ExcludeTag
    Invoke-NovaModuleToolsFreshValidationCommand -Command $unitTestCommand

    $buildValidationCommand = Get-NovaModuleToolsValidationCommand -BuiltModulePath $builtModulePath -CommandName 'Test-NovaBuild' -ExcludeTag $ExcludeTag
    Invoke-NovaModuleToolsFreshValidationCommand -Command $buildValidationCommand
} catch {
    $novaModuleToolsTestFailed = $true
    Write-Warning "Nova test workflow failed: $( $_.Exception.Message )"
} finally {
    Copy-NovaModuleToolsArtifactIfPresent -SourcePath (Join-Path $projectInfo.ProjectRoot 'artifacts/UnitTestResults.xml') -DestinationPath (Join-Path $OutputDirectory 'novamoduletools-unit-nunit.xml')
    Copy-NovaModuleToolsArtifactIfPresent -SourcePath (Join-Path $projectInfo.ProjectRoot 'artifacts/TestResults.xml') -DestinationPath (Join-Path $OutputDirectory 'novamoduletools-integration-nunit.xml')
}

if ($novaModuleToolsTestFailed) {
    exit 1
}
