BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InvokeNovaPackageUploadRequest.ps1')
}

Describe 'Get-NovaPackageUploadRequestParameterMap' {
    It 'maps basic upload fields to Invoke-WebRequest parameters' {
        $artifact = [pscustomobject]@{UploadUrl='https://x'; PackagePath='/o/x.nupkg'; Headers=@{}}
        $map = Get-NovaPackageUploadRequestParameterMap -UploadArtifact $artifact
        $map.Uri | Should -Be 'https://x'
        $map.Method | Should -Be 'Put'
        $map.InFile | Should -Be '/o/x.nupkg'
        $map.ContainsKey('Headers') | Should -BeFalse
    }

    It 'includes Headers only when at least one header is configured' {
        $artifact = [pscustomobject]@{UploadUrl='https://x'; PackagePath='/o/x.nupkg'; Headers=@{A='1'}}
        (Get-NovaPackageUploadRequestParameterMap -UploadArtifact $artifact).Headers.A | Should -Be '1'
    }
}

Describe 'Add-NovaLegacyWebRequestOption' {
    It 'returns the parameter map (UseBasicParsing flag depends on PS edition)' {
        $params = @{Uri='x'}
        $result = Add-NovaLegacyWebRequestOption -Parameters $params
        $result.Uri | Should -Be 'x'
    }
}
