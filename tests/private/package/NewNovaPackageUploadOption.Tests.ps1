BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageUploadOption.ps1')
}

Describe 'New-NovaPackageUploadOption' {
    It 'normalizes bound parameters into an option object' {
        $bound = @{
            PackagePath = '/a.nupkg'
            PackageType = 'NuGet'
            Url = 'https://x'
            Repository = 'Nexus'
            UploadPath = 'nuget'
            Headers = @{H=1}
            Token = 't'
            TokenEnvironmentVariable = 'E'
            AuthenticationScheme = 'Bearer'
        }
        $option = New-NovaPackageUploadOption -BoundParameters $bound
        $option.PackagePath | Should -Contain '/a.nupkg'
        $option.PackageType | Should -Contain 'NuGet'
        $option.Url | Should -Be 'https://x'
        $option.Token | Should -Be 't'
        $option.AuthenticationScheme | Should -Be 'Bearer'
    }
}
