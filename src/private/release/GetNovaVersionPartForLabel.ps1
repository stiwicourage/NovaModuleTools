function Get-NovaVersionPartForLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Label = 'Patch'
    )

    switch ($Label) {
        'Major' {
            return [pscustomobject]@{
                Major = $CurrentVersion.Major + 1
                Minor = 0
                Patch = 0
            }
        }
        'Minor' {
            return [pscustomobject]@{
                Major = $CurrentVersion.Major
                Minor = $CurrentVersion.Minor + 1
                Patch = 0
            }
        }
        default {
            return [pscustomobject]@{
                Major = $CurrentVersion.Major
                Minor = $CurrentVersion.Minor
                Patch = $CurrentVersion.Patch + 1
            }
        }
    }
}
