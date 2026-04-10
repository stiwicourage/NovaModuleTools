param(
    [Parameter(Mandatory)][string]$Version,
    [string]$ProjectFile = 'project.json',
    [string]$ChangelogFile = 'CHANGELOG.md'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'SemanticReleaseSupport.ps1')

Write-Host "Preparing semantic release for version $Version"

Write-ProjectJsonVersion -Path $ProjectFile -Version $Version
Write-ChangelogFileForRelease -Path $ChangelogFile -Version $Version -Date (Get-ReleaseDateString)

Import-Module NovaModuleTools -Force
Invoke-MTBuild -Verbose



