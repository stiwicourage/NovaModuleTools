BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Initialize-NovaModuleAgenticCopilotScaffold' {
    It 'replaces the short name placeholder in generated scaffold files' {
        InModuleScope $script:moduleName {
            $templateRoot = Join-Path $TestDrive 'template'
            $projectRoot = Join-Path $TestDrive 'project'
            $templateFilePath = Join-Path $templateRoot '.github/instructions/powershell-coding-standards.instructions.md'
            $null = New-Item -ItemType Directory -Path (Split-Path -Parent $templateFilePath) -Force
            Set-Content -LiteralPath $templateFilePath -Value 'Use Invoke-{{ShortName}}* for command examples.'
            Mock Get-NovaModuleAgenticCopilotTemplateRoot {$templateRoot}

            Initialize-NovaModuleAgenticCopilotScaffold -Answer @{
                ProjectName = 'NovaAgentic'
                ProjectShortName = 'NMT'
                Description = 'Agentic scaffold'
            } -ProjectRoot $projectRoot

            $content = Get-Content -LiteralPath (Join-Path $projectRoot '.github/instructions/powershell-coding-standards.instructions.md') -Raw
            $content | Should -Match 'Invoke-NMT\*'
            $content | Should -Not -Match '\{\{ShortName\}\}'
        }
    }

    It 'requires a project short name when Agentic Copilot scaffold generation is requested' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Get-NovaModuleAgenticCopilotTemplateTokenMap -Answer @{
                    ProjectName = 'NovaAgentic'
                    Description = 'Agentic scaffold'
                }
            } catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Project short name is required when Agentic Copilot setup is enabled.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.AgenticCopilotProjectShortNameMissing'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be 'ProjectShortName'
        }
    }
}
