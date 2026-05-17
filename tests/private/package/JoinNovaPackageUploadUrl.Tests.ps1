BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/JoinNovaPackageUploadUrl.ps1')
}

Describe 'Join-NovaPackageUploadUrl' {
    It 'joins URL, upload path, and escaped file name with slashes' {
        Join-NovaPackageUploadUrl -Url 'https://x/' -UploadPath '/nuget/' -PackageFileName 'X.1.0.0.nupkg' | Should -Be 'https://x/nuget/X.1.0.0.nupkg'
    }

    It 'omits the upload path when empty' {
        Join-NovaPackageUploadUrl -Url 'https://x' -UploadPath '' -PackageFileName 'X.nupkg' | Should -Be 'https://x/X.nupkg'
    }

    It 'percent-encodes special characters in the file name' {
        Join-NovaPackageUploadUrl -Url 'https://x' -PackageFileName 'a b.nupkg' | Should -Be 'https://x/a%20b.nupkg'
    }
}
