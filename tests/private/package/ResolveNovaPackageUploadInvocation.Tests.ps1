BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadInvocation.ps1')

    . (Join-Path $PSScriptRoot 'ResolveNovaPackageUploadInvocation.TestSupport.ps1')
}

Describe 'Resolve-NovaPackageUploadInvocation' {
    It 'returns one artifact per resolved file' {
        $option = [pscustomobject]@{PackagePath=@(); PackageType=@(); Url=''; Repository=''; UploadPath=''; Headers=$null; Token=''}
        $result = Resolve-NovaPackageUploadInvocation -ProjectInfo ([pscustomobject]@{}) -UploadOption $option
        @($result).Count | Should -Be 1
        $result[0].UploadUrl | Should -Be 'https://x/nuget/x.nupkg'
    }
}
