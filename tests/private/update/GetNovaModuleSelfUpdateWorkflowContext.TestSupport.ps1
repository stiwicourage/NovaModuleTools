function Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
function Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'}}
function Invoke-NovaModuleUpdateLookup {param([switch]$AllowPrereleaseNotifications,[int]$TimeoutMilliseconds) [pscustomobject]@{Version='1.1.0'}}
function Get-NovaModuleSelfUpdatePlan {param($InstalledModule,$LookupResult,$PrereleaseNotificationsEnabled) [pscustomobject]@{TargetVersion='1.1.0'; IsPrereleaseTarget=$false}}
function Stop-NovaOperation {param([string]$Message,[string]$ErrorId,$Category,$TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message),$ErrorId,$Category,$TargetObject)}
