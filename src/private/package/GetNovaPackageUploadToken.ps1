function Get-NovaPackageUploadToken {
    [CmdletBinding()]
    param(
        [AllowNull()]$AuthSettings,
        [string]$Token,
        [string]$TokenEnvironmentVariable
    )

    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        return $Token
    }

    $environmentVariableName = $TokenEnvironmentVariable
    if ( [string]::IsNullOrWhiteSpace($environmentVariableName)) {
        $environmentVariableName = Get-NovaPackageSettingValue -InputObject $AuthSettings -Name 'TokenEnvironmentVariable'
    }
    if (-not [string]::IsNullOrWhiteSpace("$environmentVariableName")) {
        return [System.Environment]::GetEnvironmentVariable("$environmentVariableName")
    }

    return Get-NovaPackageSettingValue -InputObject $AuthSettings -Name 'Token'
}

