function Get-NovaPrereleaseModuleUpdateConfirmationPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CurrentVersion,
        [Parameter(Mandatory)][string]$TargetVersion
    )

    return [pscustomobject]@{
        Caption = 'Confirm prerelease NovaModuleTools update'
        Message = @"
NovaModuleTools would update from $CurrentVersion to prerelease $TargetVersion.

Prerelease updates may be less stable than released versions.
Continue with the prerelease update?
"@
    }
}


