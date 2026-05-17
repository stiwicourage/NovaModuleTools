BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliDeployCommand.ps1')

    function ConvertFrom-NovaDeployCliArgument {param([string[]]$Arguments) return @{PackagePath = 'pkg.nupkg'}}
    function Deploy-NovaPackage {param($PackagePath, $Repository) return [pscustomobject]@{PackagePath = $PackagePath; Repository = $Repository}}
}

Describe 'Invoke-NovaCliDeployCommand' {
    It 'splats parsed options and forwarded parameters into Deploy-NovaPackage' {
        $result = Invoke-NovaCliDeployCommand -Arguments @('--path', 'pkg.nupkg') -ForwardedParameters @{Repository = 'feed'}
        $result.PackagePath | Should -Be 'pkg.nupkg'
        $result.Repository | Should -Be 'feed'
    }
}
