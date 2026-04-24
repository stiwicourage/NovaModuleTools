function Resolve-NovaPackageUploadAuthHeaderEntry {
    [CmdletBinding()]
    param(
        [AllowNull()]$AuthSettings,
        [Parameter(Mandatory)][pscustomobject]$UploadOption
    )

    $resolvedToken = Get-NovaPackageUploadToken -AuthSettings $AuthSettings -Token $UploadOption.Token -TokenEnvironmentVariable $UploadOption.TokenEnvironmentVariable
    if ( [string]::IsNullOrWhiteSpace($resolvedToken)) {
        return $null
    }

    $headerName = Get-NovaPackageUploadAuthHeaderName -AuthSettings $AuthSettings
    return [pscustomobject]@{
        Name = $headerName
        Value = Get-NovaPackageUploadAuthHeaderValue -AuthSettings $AuthSettings -AuthenticationScheme $UploadOption.AuthenticationScheme -HeaderName $headerName -Token $resolvedToken
    }
}

