BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleAgenticCopilotTemplateRoot.ps1')

    function Get-ResourceFilePath {param([string]$FileName)}
}

Describe 'Get-NovaModuleAgenticCopilotTemplateRoot' {
    It 'returns the directory that owns the agentic-copilot sentinel file' {
        Mock Get-ResourceFilePath {return '/resources/agentic-copilot/AGENTS.md'}

        $root = Get-NovaModuleAgenticCopilotTemplateRoot

        $root | Should -Be (Split-Path -Parent '/resources/agentic-copilot/AGENTS.md')
        Assert-MockCalled Get-ResourceFilePath -Times 1 -ParameterFilter {
            $FileName -like '*agentic-copilot*AGENTS.md'
        }
    }
}
