function Get-NovaSecretSourceValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$SecretSources,
        [Parameter(Mandatory)][string]$Name
    )

    if ($SecretSources.PSObject.Properties.Name -contains $Name) {
        return $SecretSources.$Name
    }

    return $null
}

function Resolve-NovaSecretValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$SecretSources
    )

    $explicitValue = Get-NovaSecretSourceValue -SecretSources $SecretSources -Name 'ExplicitValue'
    if (Test-NovaConfiguredValue -Value $explicitValue) {
        return $explicitValue
    }

    $environmentVariableName = Get-NovaFirstConfiguredValue -CandidateList @(
        (Get-NovaSecretSourceValue -SecretSources $SecretSources -Name 'ExplicitEnvironmentVariableName')
        (Get-NovaSecretSourceValue -SecretSources $SecretSources -Name 'ConfiguredEnvironmentVariableName')
        (Get-NovaSecretSourceValue -SecretSources $SecretSources -Name 'DefaultEnvironmentVariableName')
    )
    if (Test-NovaConfiguredValue -Value $environmentVariableName) {
        return Get-NovaEnvironmentVariableValue -Name $environmentVariableName
    }

    return Get-NovaFirstConfiguredValue -CandidateList @((Get-NovaSecretSourceValue -SecretSources $SecretSources -Name 'ConfiguredValue'))
}
