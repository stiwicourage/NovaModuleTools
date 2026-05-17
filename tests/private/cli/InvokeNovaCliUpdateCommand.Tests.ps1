BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliUpdateCommand.ps1')

    function ConvertFrom-NovaUpdateCliArgument {param([string[]]$Arguments) return @{}}
    function Update-NovaModuleTool {param($Verbose) return [pscustomobject]@{Invoked = $true; Verbose = $Verbose}}
}

Describe 'Invoke-NovaCliUpdateCommand' {
    It 'forwards parameters into Update-NovaModuleTool' {
        $result = Invoke-NovaCliUpdateCommand -Arguments @() -ForwardedParameters @{Verbose = $true}
        $result.Invoked | Should -BeTrue
        $result.Verbose | Should -BeTrue
    }
}
