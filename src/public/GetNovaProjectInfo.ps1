function Get-NovaProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,

        [switch]$Version
    )

    $projectInfo = Get-MTProjectInfo -Path $Path

    if ($Version) {
        return $projectInfo.Version
    }

    return $projectInfo
}
