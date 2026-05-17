BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadInvocation.ps1')

    function Get-NovaPackageUploadFileList {param($ProjectInfo, $PackagePath, $PackageType)
        return @([pscustomobject]@{Type='NuGet'; PackagePath='/o/x.nupkg'; PackageFileName='x.nupkg'})
    }
    function Resolve-NovaPackageUploadTarget {param($ProjectInfo, $Url, $Repository, $UploadPath)
        return [pscustomobject]@{Repository='Nexus'; Url='https://x'; UploadPath='nuget'; Headers=@{}; Auth=$null}
    }
    function Resolve-NovaPackageUploadHeaders {param($UploadTarget, $UploadOption) return @{H='1'}}
    function Get-NovaPackageUploadArtifact {param($PackageFileInfo, $UploadTarget, $UploadHeaders)
        return [pscustomobject]@{PackageFileName=$PackageFileInfo.PackageFileName; UploadUrl='https://x/nuget/' + $PackageFileInfo.PackageFileName}
    }
}

Describe 'Resolve-NovaPackageUploadInvocation' {
    It 'returns one artifact per resolved file' {
        $option = [pscustomobject]@{PackagePath=@(); PackageType=@(); Url=''; Repository=''; UploadPath=''; Headers=$null; Token=''}
        $result = Resolve-NovaPackageUploadInvocation -ProjectInfo ([pscustomobject]@{}) -UploadOption $option
        @($result).Count | Should -Be 1
        $result[0].UploadUrl | Should -Be 'https://x/nuget/x.nupkg'
    }
}
