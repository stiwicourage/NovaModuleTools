BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaDeployCliArgument.ps1')
    . (Join-Path $projectRoot 'src/private/cli/AddNovaCliOptionValue.ps1')
    . (Join-Path $projectRoot 'src/private/cli/AddNovaCliHeaderOption.ps1')
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliRequiredArgumentValue.ps1')

    function ConvertTo-NovaCliArgumentArray {param([hashtable]$BoundParameters, [string[]]$Arguments) return @($Arguments | Where-Object {$_})}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'ConvertFrom-NovaDeployCliArgument' {
    It 'parses all known deploy flags' {
        $options = ConvertFrom-NovaDeployCliArgument -Arguments @(
            '--repository', 'feed',
            '--url', 'https://nuget',
            '--path', 'a.nupkg',
            '--type', 'NuGet',
            '--upload-path', '/sub',
            '--token', 'tok',
            '--token-env', 'TOK',
            '--auth-scheme', 'Bearer',
            '--header', 'X-A=1'
        )
        $options.Repository | Should -Be 'feed'
        $options.Url | Should -Be 'https://nuget'
        $options.PackagePath[0] | Should -Be 'a.nupkg'
        $options.PackageType[0] | Should -Be 'NuGet'
        $options.UploadPath | Should -Be '/sub'
        $options.Token | Should -Be 'tok'
        $options.TokenEnvironmentVariable | Should -Be 'TOK'
        $options.AuthenticationScheme | Should -Be 'Bearer'
        $options.Headers['X-A'] | Should -Be '1'
    }

    It 'throws for unknown flags' {
        {ConvertFrom-NovaDeployCliArgument -Arguments @('--bogus')} | Should -Throw '*Unknown argument*'
    }
}
