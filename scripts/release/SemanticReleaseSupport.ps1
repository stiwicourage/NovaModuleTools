Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:supportRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'support'
$script:supportFileList = @(
    'Get-ReleaseDateString.ps1'
    'Get-ReleaseRepositoryUrl.ps1'
    'ConvertTo-ReleaseTagName.ps1'
    'Read-JsonFile.ps1'
    'Write-JsonFile.ps1'
    'Write-ProjectJsonVersion.ps1'
    'Get-UnreleasedSectionMatch.ps1'
    'Get-ClearedUnreleasedBody.ps1'
    'Get-ChangelogReleaseVersionList.ps1'
    'Get-AvailableReleaseVersionList.ps1'
    'Get-OrderedReleaseVersionList.ps1'
    'Get-PreviousReleaseVersion.ps1'
    'Get-ChangelogWithoutReferenceFooter.ps1'
    'Get-ChangelogReferenceFooter.ps1'
    'Format-ReleaseChangelogText.ps1'
    'Write-ChangelogFileForRelease.ps1'
)

foreach ($supportFile in $script:supportFileList) {
    . (Join-Path $script:supportRoot $supportFile)
}


