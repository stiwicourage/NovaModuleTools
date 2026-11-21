function Get-NovaPSModuleUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Module,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    $policy = @{
        Channel = if ($PrereleaseNotificationsEnabled) {'IncludePrerelease'} else {'Stable'}
        Scope = Get-NovaModuleInstallScope -ModuleBase $Module.ModuleBase
    }

    try {
        return Get-PSModuleUpdate -Module $Module -Repository 'PSGallery' -Policy $policy -ErrorAction Stop
    } catch {
        $message = @(
            'Unable to determine a NovaModuleTools update candidate.'
            "PSModuleUpdate reported: $( $_.Exception.Message )"
            'Confirm that the PowerShell Gallery is reachable and that the loaded NovaModuleTools was installed from the PowerShell Gallery, then rerun Update-NovaModuleTool.'
        ) -join [Environment]::NewLine
        Stop-NovaOperation -Message $message -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable' -Category ResourceUnavailable -TargetObject 'NovaModuleTools'
    }
}
