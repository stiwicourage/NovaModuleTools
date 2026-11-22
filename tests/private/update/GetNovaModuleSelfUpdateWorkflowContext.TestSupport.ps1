function Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
function Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'; Module=[pscustomobject]@{Name='NovaModuleTools'}}}
function Get-NovaPSModuleUpdatePlan {param($Module, [bool]$PrereleaseNotificationsEnabled) [pscustomobject]@{Disposition='UpdateAvailable'}}
function Get-NovaModuleSelfUpdatePlan {param($InstalledModule,$UpdatePlan,$PrereleaseNotificationsEnabled) [pscustomobject]@{TargetVersion='1.1.0'; IsPrereleaseTarget=$false}}
