BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadAuthHeaderValue.ps1')

    function Get-NovaPackageSettingValue {param($InputObject, $Name) return $InputObject.$Name}
}

Describe 'Get-NovaPackageUploadAuthHeaderValue' {
    It 'returns the bare token for custom header names' {
        Get-NovaPackageUploadAuthHeaderValue -AuthSettings $null -HeaderName 'X-Api-Key' -Token 't' | Should -Be 't'
    }

    It 'prepends Bearer by default for Authorization' {
        Get-NovaPackageUploadAuthHeaderValue -AuthSettings ([pscustomobject]@{Scheme=''}) -HeaderName 'Authorization' -Token 't' | Should -Be 'Bearer t'
    }

    It 'uses explicit AuthenticationScheme over configured Scheme' {
        Get-NovaPackageUploadAuthHeaderValue -AuthSettings ([pscustomobject]@{Scheme='Basic'}) -AuthenticationScheme 'Token' -HeaderName 'Authorization' -Token 't' | Should -Be 'Token t'
    }

    It 'returns the bare token when scheme is "None"' {
        Get-NovaPackageUploadAuthHeaderValue -AuthSettings ([pscustomobject]@{Scheme='None'}) -HeaderName 'Authorization' -Token 't' | Should -Be 't'
    }
}
