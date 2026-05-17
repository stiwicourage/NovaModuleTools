BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadToken.ps1')

    function Get-NovaPackageSettingValue {param($InputObject, $Name) if ($null -eq $InputObject) {return $null}; return $InputObject.$Name}
    function Resolve-NovaSecretValue {param($SecretSources) return $SecretSources.ExplicitValue}
}

Describe 'Get-NovaPackageUploadToken' {
    It 'forwards parameters to Resolve-NovaSecretValue' {
        Mock Resolve-NovaSecretValue {return 'tok'}
        Get-NovaPackageUploadToken -AuthSettings ([pscustomobject]@{Token='c'; TokenEnvironmentVariable='E'}) -Token 'x' -TokenEnvironmentVariable 'Y' | Should -Be 'tok'
        Should -Invoke Resolve-NovaSecretValue -Times 1 -ParameterFilter {$SecretSources.ExplicitValue -eq 'x' -and $SecretSources.ExplicitEnvironmentVariableName -eq 'Y'}
    }
}
