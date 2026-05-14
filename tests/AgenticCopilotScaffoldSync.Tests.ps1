BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:syncScriptPath = Join-Path $script:repoRoot 'scripts/build/Sync-AgenticCopilotScaffold.ps1'
    $script:scaffoldRoot = Join-Path $script:repoRoot 'src/resources/agentic-copilot'
    $script:manifestPath = Join-Path $script:repoRoot 'scripts/build/Sync-AgenticCopilotScaffold.psd1'

    $script:getRelativeFilePathList = {
        param([Parameter(Mandatory)][string]$RootPath)

        return Get-ChildItem -LiteralPath $RootPath -File -Recurse -Force |
                ForEach-Object {
                    [System.IO.Path]::GetRelativePath($RootPath, $_.FullName).Replace('\', '/')
                } |
                Sort-Object
    }
    $script:getAgenticScaffoldGuidanceContent = {
        return [pscustomobject]@{
            Instruction = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/copilot-instructions.md') -Raw
            QualityMatrix = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/code-quality-matrix.instructions.md') -Raw
            PlatyPsHelp = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/platyps-help.instructions.md') -Raw
            ScriptAnalyzer = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/psscriptanalyzer.instructions.md') -Raw
            CodingStandards = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/powershell-coding-standards.instructions.md') -Raw
            TestingPolicy = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/testing-policy.instructions.md') -Raw
            DeveloperAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/powershell-developer.agent.md') -Raw
            ReviewerAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/reviewer.agent.md') -Raw
            TestEngineerAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/test-engineer.agent.md') -Raw
            DeveloperSkill = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/powershell-module-development/SKILL.md') -Raw
            PesterSkill = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/pester-testing/SKILL.md') -Raw
            ImplementPrompt = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/implement-issue.prompt.md') -Raw
            ReviewPrompt = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/review-change.prompt.md') -Raw
            Agents = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'AGENTS.md') -Raw
            Contributing = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'CONTRIBUTING.md') -Raw
            Readme = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'README.md') -Raw
            CodeSceneRulesPath = Join-Path $script:scaffoldRoot '.codescene/code-health-rules.json'
        }
    }
}

Describe 'Agentic Copilot scaffold sync' {
    It 'keeps the committed starter tree aligned with the generated filtered mirror' {
        $expectedRoot = Join-Path $TestDrive 'expected-agentic-copilot'
        $null = & $script:syncScriptPath -OutputRoot $expectedRoot

        $actualFiles = @(& $script:getRelativeFilePathList -RootPath $script:scaffoldRoot)
        $expectedFiles = @(& $script:getRelativeFilePathList -RootPath $expectedRoot)

        Compare-Object -ReferenceObject $expectedFiles -DifferenceObject $actualFiles |
                Should -BeNullOrEmpty -Because 'Run ./scripts/build/Sync-AgenticCopilotScaffold.ps1 to refresh src/resources/agentic-copilot.'

        foreach ($relativePath in $expectedFiles) {
            $expectedContent = Get-Content -LiteralPath (Join-Path $expectedRoot $relativePath) -Raw
            $actualContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot $relativePath) -Raw

            $actualContent | Should -BeExactly $expectedContent -Because "$relativePath should match the generated filtered mirror."
        }
    }

    It 'omits the configured excluded source paths' {
        $manifest = Import-PowerShellDataFile -LiteralPath $script:manifestPath

        foreach ($excludedPath in $manifest.ExcludedPaths) {
            $scaffoldPath = Join-Path $script:scaffoldRoot ($excludedPath -replace '/', [System.IO.Path]::DirectorySeparatorChar)

            Test-Path -LiteralPath $scaffoldPath | Should -BeFalse
        }
    }

    It 'documents mirrored .github guidance for PowerShell, tests, and review flows' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.Instruction | Should -Match 'Do not create or maintain hand-written module `\.psm1` or module `\.psd1` files in source'
        $content.Instruction | Should -Match 'Manifest\.PowerShellHostVersion'
        $content.Instruction | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.Instruction | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.Instruction | Should -Match 'src/private/` files should expose at most one externally called function per file'
        $content.Instruction | Should -Match 'file name should match the function that owns the file'
        $content.Instruction | Should -Match 'review every changed or created text file and ensure it ends with exactly one trailing newline and no extra blank lines at the bottom'
        $content.Instruction | Should -Match 'docs/\{\{ProjectName\}\}/en-US/'
        $content.Instruction | Should -Match 'Do not exclude or suppress PSScriptAnalyzer rules'
        $content.Instruction | Should -Match 'If `run\.ps1` or `\./scripts/build/Invoke-ScriptAnalyzerCI\.ps1` reports ScriptAnalyzer findings, fix them before review, handoff, or commit'

        $content.CodingStandards | Should -Match 'Invoke-\{\{ShortName\}\}\*'
        $content.CodingStandards | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.CodingStandards | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.CodingStandards | Should -Match 'Match the file name to that top-level public function name'
        $content.CodingStandards | Should -Match 'In `src/private/`, keep at most one externally called function per file and match the file name to that entry function'
        $content.CodingStandards | Should -Match 'If two private functions are both called from outside their file, split them into separate same-named files'
        $content.CodingStandards | Should -Match 'platyps-help\.instructions\.md'
        $content.CodingStandards | Should -Match 'New-MarkdownCommandHelp'
        $content.CodingStandards | Should -Match 'Every changed or generated text file, including `\.ps1` files, must end with exactly one trailing newline and no extra blank lines at the bottom'

        $content.TestingPolicy | Should -Match 'Manifest\.PowerShellHostVersion'
        $content.TestingPolicy | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.TestingPolicy | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.TestingPolicy | Should -Match 'For every new or changed `src/\*\*/\*\.ps1` file'
        $content.TestingPolicy | Should -Match 'Source-mirrored tests should use'

        $content.ImplementPrompt | Should -Match 'Keep file/function ownership explicit: one externally called function per file'
        $content.ImplementPrompt | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.ImplementPrompt | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.ReviewPrompt | Should -Match 'code-quality-matrix\.instructions\.md'
    }

    It 'documents the best-effort quality matrix in mirrored instructions and skills' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.QualityMatrix | Should -Match 'does \*\*not\*\* require a `\.codescene/code-health-rules\.json` file in generated projects'
        $content.QualityMatrix | Should -Match '\|\s+`function_lines_of_code_warning`\s+\|\s+`16`\s+\|\s+`31`\s+\|'
        $content.QualityMatrix | Should -Match '\|\s+`function_cyclomatic_complexity_warning`\s+\|\s+`6`\s+\|\s+`11`\s+\|'
        $content.QualityMatrix | Should -Match '\|\s+`function_max_arguments`\s+\|\s+`4`\s+\|\s+—\s+\|'
        $content.QualityMatrix | Should -Match '\|\s+`function_lines_of_code_warning`\s+\|\s+`70`\s+\|\s+`500`\s+\|'
        $content.QualityMatrix | Should -Match 'unit_test_consecutive_asserts_for_large_block'

        $content.DeveloperSkill | Should -Match 'Nova generates those files under `dist/(NovaModuleTools|\{\{ProjectName\}\})/`'
        $content.DeveloperSkill | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.DeveloperSkill | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.DeveloperSkill | Should -Match 'Grouping two externally called private helpers in one file'
        $content.DeveloperSkill | Should -Match 'Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline'
        $content.DeveloperSkill | Should -Match 'PowerShell 7\.x-only'

        $content.PesterSkill | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.PesterSkill | Should -Match 'four consecutive asserts or four large assertion blocks per suite'
    }

    It 'documents valid PlatyPS help generation guidance' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.PlatyPsHelp | Should -Match 'must be valid PlatyPS command-help markdown'
        $content.PlatyPsHelp | Should -Match 'Microsoft\.PowerShell\.PlatyPS'
        $content.PlatyPsHelp | Should -Match 'New-MarkdownCommandHelp'
        $content.PlatyPsHelp | Should -Match 'Update-MarkdownCommandHelp'
        $content.PlatyPsHelp | Should -Match 'Test-MarkdownCommandHelp'
        $content.PlatyPsHelp | Should -Match 'YAML metadata block'
        $content.PlatyPsHelp | Should -Match 'Import-MarkdownCommandHelp'
        $content.PlatyPsHelp | Should -Match 'SYNOPSIS`, `SYNTAX`, optional `ALIASES`, `DESCRIPTION`, `EXAMPLES`, `PARAMETERS`, `INPUTS`, `OUTPUTS`, `NOTES`, and `RELATED LINKS`'

        $content.Instruction | Should -Match 'platyps-help\.instructions\.md'
        $content.Instruction | Should -Match 'Generate valid PlatyPS help under `docs/(NovaModuleTools|\{\{ProjectName\}\})/en-US/`'
        $content.Instruction | Should -Match 'New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, `Test-MarkdownCommandHelp`'

        $content.DeveloperSkill | Should -Match 'valid PlatyPS-compatible help'
        $content.DeveloperSkill | Should -Match 'New-MarkdownCommandHelp'
        $content.DeveloperSkill | Should -Match 'writing plain Markdown'
        $content.DeveloperAgent | Should -Match 'valid PlatyPS-compatible help docs'
        $content.DeveloperAgent | Should -Match 'New-MarkdownCommandHelp'
        $content.ReviewerAgent | Should -Match 'Test-MarkdownCommandHelp'
        $content.ImplementPrompt | Should -Match 'valid PlatyPS-compatible help under `docs/(NovaModuleTools|\{\{ProjectName\}\})/en-US/`'
        $content.ImplementPrompt | Should -Match 'New-MarkdownCommandHelp'
        $content.ReviewPrompt | Should -Match 'New-MarkdownCommandHelp'

        $content.Agents | Should -Match 'New-MarkdownCommandHelp'
        $content.Contributing | Should -Match 'New-MarkdownCommandHelp'
        $content.Readme | Should -Match 'New-MarkdownCommandHelp'
    }

    It 'documents proper PSScriptAnalyzer usage guidance' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.ScriptAnalyzer | Should -Match 'PSScriptAnalyzer is the supported static analyzer'
        $content.ScriptAnalyzer | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.ScriptAnalyzer | Should -Match 'Invoke-ScriptAnalyzer'
        $content.ScriptAnalyzer | Should -Match 'repository-approved analyzer settings through `-Settings`'
        $content.ScriptAnalyzer | Should -Match 'Invoke-ScriptAnalyzer -Fix'
        $content.ScriptAnalyzer | Should -Match 'EnableExit'

        $content.Instruction | Should -Match 'Prefer `\./scripts/build/Invoke-ScriptAnalyzerCI\.ps1` and `\./run\.ps1`'

        $content.DeveloperSkill | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.DeveloperSkill | Should -Match 'Invoke-ScriptAnalyzer'
        $content.DeveloperAgent | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.DeveloperAgent | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.TestEngineerAgent | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.TestingPolicy | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.ReviewerAgent | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.ReviewerAgent | Should -Match 'bypasses repository-approved settings'
        $content.ImplementPrompt | Should -Match 'Prefer `\./scripts/build/Invoke-ScriptAnalyzerCI\.ps1` and `\./run\.ps1`'
        $content.ReviewPrompt | Should -Match 'psscriptanalyzer\.instructions\.md'

        $content.Agents | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.Agents | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.Contributing | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.Readme | Should -Match 'psscriptanalyzer\.instructions\.md'
    }

    It 'documents agent and starter expectations without adding a CodeScene config file' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.DeveloperAgent | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.DeveloperAgent | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.DeveloperAgent | Should -Match 'Public/private file ownership still follows the one externally called function per file rule'
        $content.DeveloperAgent | Should -Match 'Every changed or generated text file has been checked and ends with exactly one trailing newline and no extra blank lines at the bottom'

        $content.TestEngineerAgent | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.ReviewerAgent | Should -Match 'Flag public files that do not keep exactly one top-level function'
        $content.ReviewerAgent | Should -Match 'flag private files that group multiple externally called functions'
        $content.ReviewerAgent | Should -Match 'code-quality-matrix\.instructions\.md'

        $content.Agents | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.Agents | Should -Match 'does not require `\.codescene/code-health-rules\.json`'
        $content.Agents | Should -Match 'End every changed or generated text file with exactly one trailing newline and no extra blank lines at the bottom'

        $content.Contributing | Should -Match 'keep one externally called function per file and match the file name to that function'
        $content.Contributing | Should -Match 'does not require `\.codescene/code-health-rules\.json`'
        $content.Contributing | Should -Match 'make every changed or generated text file end with exactly one trailing newline and no extra blank lines at the bottom'

        $content.Readme | Should -Match 'ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`'
        $content.Readme | Should -Match 'without requiring a `\.codescene/code-health-rules\.json`'
        $content.Readme | Should -Match 'If `run\.ps1` or `Invoke-ScriptAnalyzerCI\.ps1` reports ScriptAnalyzer findings, fix them before review or handoff'
        $content.Readme | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.Readme | Should -Match 'Make every changed or generated text file end with exactly one trailing newline and no extra blank lines at the bottom before handoff'
        $content.Readme | Should -Match 'If it is `5\.1`, do not introduce PowerShell 7\.x-only features'
        $content.Readme | Should -Match 'every new or changed `src/\*\*/\*\.ps1` file should have one focused `\.Tests\.ps1` file'

        Test-Path -LiteralPath $content.CodeSceneRulesPath | Should -BeFalse
    }
}
