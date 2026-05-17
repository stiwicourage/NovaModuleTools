BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/FormatNovaCliVersionString.ps1')
}

Describe 'Format-NovaCliVersionString' {
    It 'joins the name and version with a space' {
        Format-NovaCliVersionString -Name 'NovaModuleTools' -Version '1.2.3' | Should -Be 'NovaModuleTools 1.2.3'
    }
}
