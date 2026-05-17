BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadStatusCode.ps1')
}

Describe 'Get-NovaPackageUploadStatusCode' {
    It 'returns $null for null response' {
        Get-NovaPackageUploadStatusCode -Response $null | Should -BeNullOrEmpty
    }

    It 'returns the int status code from a response object' {
        Get-NovaPackageUploadStatusCode -Response ([pscustomobject]@{StatusCode=201}) | Should -Be 201
    }

    It 'returns $null when StatusCode property is missing' {
        Get-NovaPackageUploadStatusCode -Response ([pscustomobject]@{Other=1}) | Should -BeNullOrEmpty
    }
}
