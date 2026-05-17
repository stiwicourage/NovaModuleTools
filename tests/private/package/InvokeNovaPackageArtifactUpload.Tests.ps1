BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageArtifactUpload.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
    function Invoke-NovaPackageUploadRequest {param($UploadArtifact) return [pscustomobject]@{StatusCode=201}}
    function Get-NovaPackageUploadStatusCode {param($Response) return $Response.StatusCode}
}

Describe 'Invoke-NovaPackageArtifactUpload' {
    BeforeEach {
        $script:file = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.nupkg')
        Set-Content -LiteralPath $script:file -Value 'x'
        $script:artifact = [pscustomobject]@{Type='NuGet'; PackagePath=$script:file; PackageFileName='x.nupkg'; Repository='r'; UploadUrl='https://x'; Headers=@{}}
    }
    AfterEach {
        Remove-Item -LiteralPath $script:file -ErrorAction SilentlyContinue
    }

    It 'throws when the package file does not exist' {
        Remove-Item -LiteralPath $script:file -Force
        {Invoke-NovaPackageArtifactUpload -UploadArtifact $script:artifact} | Should -Throw '*Package file not found*'
    }

    It 'returns a result object including the status code on success' {
        $result = Invoke-NovaPackageArtifactUpload -UploadArtifact $script:artifact
        $result.StatusCode | Should -Be 201
        $result.UploadUrl | Should -Be 'https://x'
    }

    It 'wraps upload errors into Stop-NovaOperation' {
        Mock Invoke-NovaPackageUploadRequest {throw 'boom'}
        {Invoke-NovaPackageArtifactUpload -UploadArtifact $script:artifact} | Should -Throw '*Package upload failed*'
    }
}
