function Get-NovaModuleSelfUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InstalledModule,
        [Parameter(Mandatory)][object]$UpdatePlan,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    if ($UpdatePlan.Disposition -cnotin @('UpdateAvailable', 'UpToDate', 'AlreadyInstalledRestartRequired')) {
        $message = "PSModuleUpdate returned an unsupported update disposition '$( $UpdatePlan.Disposition )'. Update PSModuleUpdate, then rerun Update-NovaModuleTool."
        Stop-NovaOperation -Message $message -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable' -Category InvalidResult -TargetObject 'NovaModuleTools'
    }

    return ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $InstalledModule -UpdatePlan $UpdatePlan -PrereleaseNotificationsEnabled $PrereleaseNotificationsEnabled
}
