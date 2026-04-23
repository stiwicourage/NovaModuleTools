function Resolve-NovaPackageUploadHeaders {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Upload headers is the domain term represented by this helper because it resolves a header collection.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$UploadTarget,
        [Parameter(Mandatory)][pscustomobject]$UploadOption
    )

    $resolvedHeaders = Merge-NovaPackageSettingTable -BaseSettings $UploadTarget.Headers -OverrideSettings $UploadOption.Headers
    $authHeaderEntry = Resolve-NovaPackageUploadAuthHeaderEntry -AuthSettings $UploadTarget.Auth -UploadOption $UploadOption
    if ($null -eq $authHeaderEntry) {
        return $resolvedHeaders
    }

    $resolvedHeaders[$authHeaderEntry.Name] = $authHeaderEntry.Value
    return $resolvedHeaders
}

