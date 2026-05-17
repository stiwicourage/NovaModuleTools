function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
    $exception = [System.Exception]::new($Message)
    $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $record
}
function Get-NovaProjectPackageSettingsTable {param([hashtable]$ProjectData)}
function Get-NovaResolvedProjectPackageTypeList {param([hashtable]$PackageSettings)}
function Get-NovaResolvedProjectPackageOutputDirectorySettings {param([hashtable]$PackageSettings, [string]$ProjectRoot)}

function Test-NovaPackageSettingMissing {
    param(
        [hashtable]$PackageSettings,
        [string]$Name,
        [switch]$TreatWhitespaceAsMissing
    )

    $existing = $PackageSettings[$Name]
    if ($null -eq $existing) {
        return $true
    }

    if (-not $TreatWhitespaceAsMissing) {
        return $false
    }

    return ($existing -is [string]) -and [string]::IsNullOrWhiteSpace($existing)
}

function Set-NovaPackageSettingDefault {
    param([hashtable]$PackageSettings, [string]$Name, $Value, [switch]$TreatWhitespaceAsMissing)

    if (Test-NovaPackageSettingMissing -PackageSettings $PackageSettings -Name $Name -TreatWhitespaceAsMissing:$TreatWhitespaceAsMissing) {
        $PackageSettings[$Name] = $Value
    }
}
