function Set-NovaPackageSettingDefault {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only mutates an in-memory metadata dictionary and does not change external state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$PackageSettings,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [switch]$TreatWhitespaceAsMissing
    )

    $hasValue = $PackageSettings.Contains($Name)
    if ($hasValue -and $TreatWhitespaceAsMissing) {
        $hasValue = -not [string]::IsNullOrWhiteSpace("$( $PackageSettings[$Name] )")
    }

    if (-not $hasValue) {
        $null = $PackageSettings[$Name] = $Value
    }
}

