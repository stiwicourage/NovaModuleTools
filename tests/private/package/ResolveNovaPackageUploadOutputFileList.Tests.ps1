BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadOutputFileList.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
    function Resolve-NovaPackageUploadTypeList {param($ProjectInfo, $PackageType) return @('NuGet')}
    function Get-NovaPackageOutputDirectory {param($ProjectInfo) return $script:outputDirectory}
    function Resolve-NovaPackageUploadOutputFileSet {param($OutputDirectory, $ProjectInfo, $PackageType)
        return @([pscustomobject]@{Type=$PackageType; PackagePath=Join-Path $OutputDirectory 'x.nupkg'})
    }
}

Describe 'Resolve-NovaPackageUploadOutputFileList' {
    BeforeEach {
        $script:outputDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:outputDirectory | Out-Null
    }
    AfterEach {Remove-Item -LiteralPath $script:outputDirectory -Recurse -Force -ErrorAction SilentlyContinue}

    It 'throws when the output directory does not exist' {
        Remove-Item -LiteralPath $script:outputDirectory -Recurse -Force
        {Resolve-NovaPackageUploadOutputFileList -ProjectInfo ([pscustomobject]@{})} | Should -Throw '*Package output directory not found*'
    }

    It 'returns one resolved file set per resolved type' {
        $files = Resolve-NovaPackageUploadOutputFileList -ProjectInfo ([pscustomobject]@{})
        @($files).Count | Should -Be 1
    }
}
