BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadTargetUrl.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaPackageUploadTargetUrl.TestSupport.ps1')
}

Describe 'Get-NovaPackageUploadTargetUrl' {
    It 'prefers the explicit URL over configured values' {
        Get-NovaPackageUploadTargetUrl -PackageSettings ([pscustomobject]@{}) -RepositorySettings ([pscustomobject]@{Url='repo'}) -Url 'override' | Should -Be 'override'
    }

    It 'falls back through repository, RepositoryUrl, and RawRepositoryUrl' {
        $package = [pscustomobject]@{RepositoryUrl=''; RawRepositoryUrl='raw'}
        Get-NovaPackageUploadTargetUrl -PackageSettings $package -RepositorySettings ([pscustomobject]@{Url=''}) | Should -Be 'raw'
    }

    It 'throws when no URL is configured' {
        $package = [pscustomobject]@{RepositoryUrl=''; RawRepositoryUrl=''}
        {Get-NovaPackageUploadTargetUrl -PackageSettings $package -RepositorySettings ([pscustomobject]@{Url=''})} | Should -Throw '*Upload target URL is missing*'
    }
}
