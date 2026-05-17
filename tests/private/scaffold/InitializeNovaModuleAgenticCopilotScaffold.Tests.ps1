BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
    $script:newTextFileFormattingTemplate = {
        param(
            [Parameter(Mandatory)][string]$TemplateRoot
        )

        $formattingScriptPath = Join-Path $TemplateRoot 'scripts/build/Test-TextFileFormatting.ps1'
        $formattingTestPath = Join-Path $TemplateRoot 'tests/TextFileFormatting.Tests.ps1'
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $formattingScriptPath) -Force
        $null = New-Item -ItemType Directory -Path (Split-Path -Parent $formattingTestPath) -Force
        Set-Content -LiteralPath $formattingScriptPath -Value "Write-Host 'formatting'" -Encoding utf8 -NoNewline
        Set-Content -LiteralPath $formattingTestPath -Value "Describe 'formatting' {}" -Encoding utf8 -NoNewline
    }
    $script:newReadmeFallbackTokenMap = {
        [ordered]@{
            '{{ProjectName}}' = 'NovaAgentic'
            '{{ShortName}}' = 'NMT'
            '{{ProjectDescription}}' = 'Agentic scaffold.'
            '{{StartHereBody}}' = 'Start here'
        }
    }
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
            $content | Should -Match "(\r\n|\n)$"
            $content | Should -Not -Match "(\r\n|\n){2,}$"
        }
    }

    It 'handles the text file formatting guardrails for <Scenario>' -ForEach @(
        @{
            Scenario = 'Pester-enabled standard scaffolds'
            TemplateName = 'template-with-formatting'
            ProjectName = 'project-with-formatting'
            EnablePester = 'Yes'
            Example = $false
            ExpectFormattingTest = $true
        }
        @{
            Scenario = 'standard scaffolds without Pester'
            TemplateName = 'template-without-pester'
            ProjectName = 'project-without-pester'
            EnablePester = 'No'
            Example = $false
            ExpectFormattingTest = $false
        }
        @{
            Scenario = 'example scaffolds'
            TemplateName = 'template-example'
            ProjectName = 'project-example'
            EnablePester = $null
            Example = $true
            ExpectFormattingTest = $true
        }
    ) {
        $templateRoot = Join-Path $TestDrive $TemplateName
        $projectRoot = Join-Path $TestDrive $ProjectName
        & $script:newTextFileFormattingTemplate -TemplateRoot $templateRoot

        InModuleScope $script:moduleName -Parameters @{
            templateRoot = $templateRoot
            projectRoot = $projectRoot
            enablePester = $EnablePester
            example = $Example
        } {
            param($templateRoot, $projectRoot, $enablePester, $example)

            Mock Get-NovaModuleAgenticCopilotTemplateRoot {$templateRoot}

            $answer = @{
                ProjectName = 'NovaAgentic'
                ProjectShortName = 'NMT'
                Description = 'Agentic scaffold'
            }
            if ($null -ne $enablePester) {
                $answer.EnablePester = $enablePester
            }

            Initialize-NovaModuleAgenticCopilotScaffold -Answer $answer -ProjectRoot $projectRoot -Example:$example
        }

        (Test-Path -LiteralPath (Join-Path $projectRoot 'scripts/build/Test-TextFileFormatting.ps1')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $projectRoot 'tests/TextFileFormatting.Tests.ps1')) | Should -Be $ExpectFormattingTest
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

    It 'defaults the project description when the answer description is blank' {
        InModuleScope $script:moduleName {
            $tokenMap = Get-NovaModuleAgenticCopilotTemplateTokenMap -Answer @{
                ProjectName = 'NovaAgentic'
                ProjectShortName = 'NMT'
                Description = ' '
            }

            $tokenMap['{{ProjectDescription}}'] | Should -Be 'NovaAgentic is a PowerShell module project scaffolded with NovaModuleTools.'
        }
    }

    It 'falls back to the template README when <Scenario>' -ForEach @(
        @{
            Scenario = 'the example README is missing'
            ProjectName = 'missing-readme'
            ReadmeContent = $null
        }
        @{
            Scenario = 'the example README has no secondary heading'
            ProjectName = 'readme-without-heading'
            ReadmeContent = '# Example project'
        }
    ) {
        $projectRoot = Join-Path $TestDrive $ProjectName
        $null = New-Item -ItemType Directory -Path $projectRoot -Force
        if ($null -ne $ReadmeContent) {
            $readmePath = Join-Path $projectRoot 'README.md'
            Set-Content -LiteralPath $readmePath -Value $ReadmeContent -Encoding utf8 -NoNewline
        }
        $tokenMap = & $script:newReadmeFallbackTokenMap

        InModuleScope $script:moduleName -Parameters @{
            tokenMap = $tokenMap
            projectRoot = $projectRoot
        } {
            param($tokenMap, $projectRoot)

            $content = Get-NovaModuleAgenticCopilotReadmeContent -TemplateContent 'Name: {{ProjectName}}' -TokenMap $tokenMap -ProjectRoot $projectRoot -Example

            $content | Should -Be 'Name: NovaAgentic'
        }
    }
}
