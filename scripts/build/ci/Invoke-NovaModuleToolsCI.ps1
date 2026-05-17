param(
    [string]$OutputDirectory = './artifacts',
    [string[]]$ExcludeTag = @()
)

Set-StrictMode -Version Latest

function Copy-NovaModuleToolsTestResultIfPresent {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ArtifactsDirectory
    )

    $sourcePath = Join-Path $ProjectRoot 'artifacts/TestResults.xml'
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $ArtifactsDirectory 'novamoduletools-nunit.xml') -Force
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
        Test-NovaBuild -ExcludeTagFilter $ExcludeTag
    } else {
        Test-NovaBuild
    }
} catch {
    $novaModuleToolsTestFailed = $true
    Write-Warning "Test-NovaBuild failed: $( $_.Exception.Message )"
} finally {
    Copy-NovaModuleToolsTestResultIfPresent -ProjectRoot $projectInfo.ProjectRoot -ArtifactsDirectory $OutputDirectory
}

if ($novaModuleToolsTestFailed) {
    exit 1
}
