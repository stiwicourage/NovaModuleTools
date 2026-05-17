BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadTargetUrl.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
    function Get-NovaPackageSettingValue {param($InputObject, $Name)
        if ($null -eq $InputObject) {return $null}
        if ($InputObject -is [System.Collections.IDictionary]) {return $InputObject[$Name]}
        $prop = $InputObject.PSObject.Properties[$Name]
        if ($null -eq $prop) {return $null}
        return $prop.Value
    }
    function Get-NovaFirstConfiguredValue {param($CandidateList)
        foreach ($c in $CandidateList) {if (-not [string]::IsNullOrWhiteSpace("$c")) {return $c}}
        return $null
    }
    function Test-NovaConfiguredValue {param($Value) return -not [string]::IsNullOrWhiteSpace("$Value")}
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
