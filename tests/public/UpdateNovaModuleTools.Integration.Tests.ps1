BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Update-NovaModuleTool integration' {
    It 'exports the legacy alias from the built module' {
        (Get-Alias -Name 'Update-NovaModuleTools').Definition | Should -Be 'Update-NovaModuleTool'
    }

    It 'supports WhatIf from the built module' {
        $thrown = $null

        try {
            Update-NovaModuleTool -WhatIf | Out-Null
        } catch {
            $thrown = $_
        }

        if ($null -eq $thrown) {
            return
        }

        $thrown.Exception.Message | Should -Be 'Unable to determine a NovaModuleTools update candidate. Try again when the PowerShell Gallery is reachable.'
    }
}
