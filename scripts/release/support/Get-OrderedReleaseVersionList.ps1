function Get-OrderedReleaseVersionList {
    param(
        [Parameter(Mandatory)][string[]]$Versions
    )

    return @(
    $Versions |
            Sort-Object -Unique |
            ForEach-Object {
                [pscustomobject]@{
                    Version = $_
                    SemanticVersion = [System.Management.Automation.SemanticVersion]::Parse($_)
                }
            } |
            Sort-Object SemanticVersion |
            ForEach-Object {$_.Version}
    )
}

