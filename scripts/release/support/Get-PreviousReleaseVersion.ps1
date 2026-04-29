function Get-PreviousReleaseVersion {
    param(
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string[]]$AvailableVersions
    )

    $orderedVersions = Get-OrderedReleaseVersionList -Versions $AvailableVersions
    $currentVersionValue = [System.Management.Automation.SemanticVersion]::Parse($Version)

    return @(
    $orderedVersions |
            Where-Object {
                [System.Management.Automation.SemanticVersion]::Parse($_) -lt $currentVersionValue
            } |
            Select-Object -Last 1
    )[0]
}
