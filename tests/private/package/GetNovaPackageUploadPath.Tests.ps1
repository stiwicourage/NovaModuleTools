BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadPath.ps1')

    function Get-NovaPackageSettingValue {param($InputObject, $Name) return $InputObject.$Name}
    function Get-NovaFirstConfiguredValue {param($CandidateList)
        foreach ($candidate in $CandidateList) {if (-not [string]::IsNullOrWhiteSpace("$candidate")) {return $candidate}}
        return $null
    }
}

Describe 'Get-NovaPackageUploadPath' {
    It 'prefers the explicit upload path over configured settings' {
        Get-NovaPackageUploadPath -PackageSettings ([pscustomobject]@{UploadPath='pkg'}) -RepositorySettings ([pscustomobject]@{UploadPath='repo'}) -UploadPath 'override' | Should -Be 'override'
    }

    It 'falls back to repository settings when explicit is empty' {
        Get-NovaPackageUploadPath -PackageSettings ([pscustomobject]@{UploadPath='pkg'}) -RepositorySettings ([pscustomobject]@{UploadPath='repo'}) -UploadPath '' | Should -Be 'repo'
    }

    It 'falls back to package settings when repository is empty' {
        Get-NovaPackageUploadPath -PackageSettings ([pscustomobject]@{UploadPath='pkg'}) -RepositorySettings ([pscustomobject]@{UploadPath=''}) | Should -Be 'pkg'
    }

    It 'returns an empty string when no candidate is configured' {
        Get-NovaPackageUploadPath -PackageSettings ([pscustomobject]@{UploadPath=''}) -RepositorySettings ([pscustomobject]@{UploadPath=''}) | Should -Be ''
    }
}
