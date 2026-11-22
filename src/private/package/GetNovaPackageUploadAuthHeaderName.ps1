function Get-NovaPackageUploadAuthHeaderName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]$AuthSettings
    )

    $headerName = Get-NovaPackageSettingValue -InputObject $AuthSettings -Name 'HeaderName'
    if ( [string]::IsNullOrWhiteSpace("$headerName")) {
        return 'Authorization'
    }

    return "$headerName".Trim()
}
