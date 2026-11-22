function ConvertTo-NovaModuleSelfUpdatePlan {
    param([pscustomobject]$InstalledModule, [object]$UpdatePlan, [bool]$PrereleaseNotificationsEnabled)
    return [pscustomobject]@{Disposition = $UpdatePlan.Disposition}
}

function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message), $ErrorId, $Category, $TargetObject)}
