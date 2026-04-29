function Get-NovaPackageUploadToken {
    [CmdletBinding()]
    param(
        [AllowNull()]$AuthSettings,
        [string]$Token,
        [string]$TokenEnvironmentVariable
    )

    return Resolve-NovaSecretValue -SecretSources ([pscustomobject]@{
        ExplicitValue = $Token
        ExplicitEnvironmentVariableName = $TokenEnvironmentVariable
        ConfiguredEnvironmentVariableName = Get-NovaPackageSettingValue -InputObject $AuthSettings -Name 'TokenEnvironmentVariable'
        ConfiguredValue = Get-NovaPackageSettingValue -InputObject $AuthSettings -Name 'Token'
    })
}
