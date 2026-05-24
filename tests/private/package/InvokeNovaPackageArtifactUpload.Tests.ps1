BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageArtifactUpload.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaPackageArtifactUpload.TestSupport.ps1')
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
        {Invoke-NovaPackageArtifactUpload -UploadArtifact $script:artifact} | Should -Throw '*Run New-NovaModulePackage first or provide a valid -PackagePath*'
    }

    It 'returns a result object including the status code on success' {
        $result = Invoke-NovaPackageArtifactUpload -UploadArtifact $script:artifact
        $result.StatusCode | Should -Be 201
        $result.UploadUrl | Should -Be 'https://x'
    }

    It 'wraps upload errors into Stop-NovaOperation' {
        Mock Invoke-NovaPackageUploadRequest {throw 'boom'}
        {Invoke-NovaPackageArtifactUpload -UploadArtifact $script:artifact} | Should -Throw '*Check the upload URL, authentication token, and network access, then try again*'
    }
}
