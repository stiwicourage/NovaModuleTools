function Confirm-NovaPrereleaseModuleUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Cmdlet,
        [Parameter(Mandatory)][string]$CurrentVersion,
        [Parameter(Mandatory)][string]$TargetVersion
    )

    $prompt = Get-NovaPrereleaseModuleUpdateConfirmationPrompt -CurrentVersion $CurrentVersion -TargetVersion $TargetVersion
    return (Read-AwesomeChoicePrompt -Ask $prompt -HostUi $Cmdlet.Host.UI) -eq 'Y'
}
