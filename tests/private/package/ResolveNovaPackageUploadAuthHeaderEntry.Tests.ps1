BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadAuthHeaderEntry.ps1')

    function Get-NovaPackageUploadToken {param($AuthSettings, $Token, $TokenEnvironmentVariable) return 'tok'}
    function Get-NovaPackageUploadAuthHeaderName {param($AuthSettings) return 'Authorization'}
    function Get-NovaPackageUploadAuthHeaderValue {param($AuthSettings, $AuthenticationScheme, $HeaderName, $Token) return "Bearer $Token"}
}

Describe 'Resolve-NovaPackageUploadAuthHeaderEntry' {
    It 'returns $null when token resolution is blank' {
        Mock Get-NovaPackageUploadToken {return ''}
        Resolve-NovaPackageUploadAuthHeaderEntry -AuthSettings $null -UploadOption ([pscustomobject]@{Token=''; TokenEnvironmentVariable=''; AuthenticationScheme=''}) | Should -BeNullOrEmpty
    }

    It 'returns a header name and value when a token is resolved' {
        $entry = Resolve-NovaPackageUploadAuthHeaderEntry -AuthSettings $null -UploadOption ([pscustomobject]@{Token='t'; TokenEnvironmentVariable=''; AuthenticationScheme=''})
        $entry.Name | Should -Be 'Authorization'
        $entry.Value | Should -Be 'Bearer tok'
    }
}
