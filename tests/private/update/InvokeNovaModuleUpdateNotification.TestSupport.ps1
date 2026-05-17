function Read-NovaUpdateNotificationPreference {}
function Get-NovaInstalledModuleVersionInfo {}
function Invoke-NovaModuleUpdateLookup {param([switch]$AllowPrereleaseNotifications, [int]$TimeoutMilliseconds)}
function Get-NovaAvailableSemanticVersion {param($VersionInfo)}
function Test-NovaStableUpdateAvailable {param($StableVersion, $InstalledVersion)}
function Test-NovaPrereleaseUpdateAvailable {param($LookupResult, $InstalledVersion, $StableVersion, $PrereleaseNotificationsEnabled)}
function Write-NovaAvailableModuleUpdateWarning {param($CurrentVersion, $AvailableVersion, [switch]$Prerelease)}
