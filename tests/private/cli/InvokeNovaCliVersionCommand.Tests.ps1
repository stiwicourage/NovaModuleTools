BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliVersionCommand.ps1')

    function ConvertFrom-NovaVersionCliArgument {param([string[]]$Arguments) return @{Installed = $false}}
    function Get-NovaInstalledProjectVersion {return '0.9.0'}
    function Get-NovaProjectInfo {return [pscustomobject]@{ProjectName = 'MyTool'; Version = '1.2.3'}}
    function Format-NovaCliVersionString {param($Name, $Version) return "$Name $Version"}
}

Describe 'Invoke-NovaCliVersionCommand' {
    It 'returns project info as formatted string by default' {
        Invoke-NovaCliVersionCommand -Arguments @() -ForwardedParameters @{} | Should -Be 'MyTool 1.2.3'
    }

    It 'returns installed version when --installed' {
        Mock ConvertFrom-NovaVersionCliArgument {return @{Installed = $true}}
        Invoke-NovaCliVersionCommand -Arguments @('--installed') -ForwardedParameters @{} | Should -Be '0.9.0'
    }
}
