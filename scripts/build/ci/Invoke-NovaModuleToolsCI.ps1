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

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..' '..')).Path
Set-Location $repoRoot
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Import-Module NovaModuleTools -ErrorAction Stop

Invoke-NovaBuild

$projectInfo = Get-NovaProjectInfo
$builtModulePath = $projectInfo.OutputModuleDir
Remove-Module $projectInfo.ProjectName -ErrorAction SilentlyContinue
Import-Module $builtModulePath -Force
$projectInfo = Get-NovaProjectInfo

$novaModuleToolsTestFailed = $false
try {
    if (@($ExcludeTag).Count -gt 0) {
        Invoke-NovaTest -ExcludeTagFilter $ExcludeTag
        Test-NovaBuild -ExcludeTagFilter $ExcludeTag
    } else {
        Invoke-NovaTest
        Test-NovaBuild
    }
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
