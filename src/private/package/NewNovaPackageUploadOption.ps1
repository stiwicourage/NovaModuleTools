function New-NovaPackageUploadOption {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only normalizes bound parameters into an options object and does not mutate state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    return [pscustomobject]@{
        PackagePath = @($BoundParameters['PackagePath'])
        PackageType = @($BoundParameters['PackageType'])
        Url = $BoundParameters['Url']
        Repository = $BoundParameters['Repository']
        UploadPath = $BoundParameters['UploadPath']
        Headers = $BoundParameters['Headers']
        Token = $BoundParameters['Token']
        TokenEnvironmentVariable = $BoundParameters['TokenEnvironmentVariable']
        AuthenticationScheme = $BoundParameters['AuthenticationScheme']
    }
}
