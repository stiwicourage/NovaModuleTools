function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
    $exception = [System.Exception]::new($Message)
    $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $record
}
function Get-NovaProjectPackageSettingsTable {param([hashtable]$ProjectData)}
function Get-NovaResolvedProjectPackageTypeList {param([hashtable]$PackageSettings)}
function Get-NovaResolvedProjectPackageOutputDirectorySettings {param([hashtable]$PackageSettings, [string]$ProjectRoot)}
function Set-NovaPackageSettingDefault {
    param([hashtable]$PackageSettings, [string]$Name, $Value, [switch]$TreatWhitespaceAsMissing)
    $existing = $PackageSettings[$Name]
    $missing = $null -eq $existing
    if (-not $missing -and $TreatWhitespaceAsMissing -and $existing -is [string]) {
        $missing = [string]::IsNullOrWhiteSpace($existing)
    }
    if ($missing) { $PackageSettings[$Name] = $Value }
}
