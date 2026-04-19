function Resolve-NovaPackageUploadHeaders {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Upload headers is the domain term represented by this helper because it resolves a header collection.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$UploadTarget,
        [Parameter(Mandatory)][pscustomobject]$UploadOption
    )

    $resolvedHeaders = Merge-NovaPackageSettingTable -BaseSettings $UploadTarget.Headers -OverrideSettings $UploadOption.Headers
    $resolvedToken = Get-NovaPackageUploadToken -AuthSettings $UploadTarget.Auth -Token $UploadOption.Token -TokenEnvironmentVariable $UploadOption.TokenEnvironmentVariable
    if ( [string]::IsNullOrWhiteSpace($resolvedToken)) {
        return $resolvedHeaders
    }

    $headerName = Get-NovaPackageUploadAuthHeaderName -AuthSettings $UploadTarget.Auth
    $resolvedHeaders[$headerName] = Get-NovaPackageUploadAuthHeaderValue -AuthSettings $UploadTarget.Auth -AuthenticationScheme $UploadOption.AuthenticationScheme -HeaderName $headerName -Token $resolvedToken
    return $resolvedHeaders
}

