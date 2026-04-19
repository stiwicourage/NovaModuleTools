function Get-NovaPackageUploadAuthHeaderValue {
    [CmdletBinding()]
    param(
        [AllowNull()]$AuthSettings,
        [string]$AuthenticationScheme,
        [Parameter(Mandatory)][string]$HeaderName,
        [Parameter(Mandatory)][string]$Token
    )

    if (-not $HeaderName.Equals('Authorization', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Token
    }

    $scheme = $AuthenticationScheme
    if ( [string]::IsNullOrWhiteSpace($scheme)) {
        $scheme = Get-NovaPackageSettingValue -InputObject $AuthSettings -Name 'Scheme'
    }
    if ( [string]::IsNullOrWhiteSpace("$scheme")) {
        $scheme = 'Bearer'
    }
    if ( "$scheme".Trim().Equals('None', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Token
    }

    return "$("$scheme".Trim() ) $Token"
}

