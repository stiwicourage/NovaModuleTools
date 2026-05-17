BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadAuthHeaderName.ps1')

    function Get-NovaPackageSettingValue {param($InputObject, $Name) return $InputObject.$Name}
}

Describe 'Get-NovaPackageUploadAuthHeaderName' {
    It 'defaults to Authorization when no HeaderName is configured' {
        Get-NovaPackageUploadAuthHeaderName -AuthSettings ([pscustomobject]@{HeaderName=''}) | Should -Be 'Authorization'
    }

    It 'returns the configured trimmed name' {
        Get-NovaPackageUploadAuthHeaderName -AuthSettings ([pscustomobject]@{HeaderName='  X-Api-Key  '}) | Should -Be 'X-Api-Key'
    }
}
