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
            RepositoryConventions = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/repository-conventions.instructions.md') -Raw
            TerminalUxInstruction = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/terminal-ux-design.instructions.md') -Raw
            QualityMatrix = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/code-quality-matrix.instructions.md') -Raw
            PlatyPsHelp = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/platyps-help.instructions.md') -Raw
            ScriptAnalyzer = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/psscriptanalyzer.instructions.md') -Raw
            CodingStandards = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/powershell-coding-standards.instructions.md') -Raw
            TestingPolicy = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/testing-policy.instructions.md') -Raw
            ArchitectAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/architect.agent.md') -Raw
            DeveloperAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/powershell-developer.agent.md') -Raw
            ReviewerAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/reviewer.agent.md') -Raw
            TestEngineerAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/test-engineer.agent.md') -Raw
            ReleaseManagerAgent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/release-manager.agent.md') -Raw
            TerminalUxSkill = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/terminal-ux-design/SKILL.md') -Raw
            DeveloperSkill = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/powershell-module-development/SKILL.md') -Raw
            PesterSkill = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/pester-testing/SKILL.md') -Raw
            ImplementPrompt = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/implement-issue.prompt.md') -Raw
            ImproveCoveragePrompt = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/improve-test-coverage.prompt.md') -Raw
            PrepareReleasePrompt = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/prepare-release.prompt.md') -Raw
            ReviewPrompt = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/review-change.prompt.md') -Raw
            Agents = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'AGENTS.md') -Raw
            Contributing = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'CONTRIBUTING.md') -Raw
            Readme = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'README.md') -Raw
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

    It 'keeps the slim Copilot index thin and pointing to canonical rule files' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.Instruction | Should -Match 'Index of repository-wide Copilot guidance'
        $content.Instruction | Should -Match 'Task map'
        $content.Instruction | Should -Match 'repository-conventions\.instructions\.md'
        $content.Instruction | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.Instruction | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.Instruction | Should -Match 'platyps-help\.instructions\.md'
        $content.Instruction | Should -Match 'design-change\.prompt\.md'
        $content.Instruction | Should -Match 'implement-issue\.prompt\.md'
        $content.Instruction | Should -Match '@\.github/prompts/<name>\.prompt\.md'
    }

    It 'documents cross-cutting repository conventions in their canonical instruction file' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.RepositoryConventions | Should -Match 'Do not create or maintain hand-written module `\.psm1` or module `\.psd1` files in source'
        $content.RepositoryConventions | Should -Match 'Manifest\.PowerShellHostVersion'
        $content.RepositoryConventions | Should -Match 'src/private/` files expose at most one externally called function per file'
        $content.RepositoryConventions | Should -Match 'file name matches the function name'
        $content.RepositoryConventions | Should -Match 'review every changed or created text file and ensure it ends with exactly one trailing newline'
        $content.RepositoryConventions | Should -Match 'local quality loop: use the repository quality wrapper when one exists; otherwise run ScriptAnalyzer, build, `Invoke-NovaTest`, and `Test-NovaBuild` in the documented project order'
        $content.RepositoryConventions | Should -Match 'test validation: `Invoke-NovaTest` for unit-test validation, then `Test-NovaBuild` for build-validation integration coverage'
        $content.RepositoryConventions | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.RepositoryConventions | Should -Match 'Conventional Commit format'
    }

    It 'documents source maintainability guidance in mirrored instructions and skills' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.QualityMatrix | Should -Match 'maintainability guidance for PowerShell source and helper scripts'
        $content.QualityMatrix | Should -Match 'ten widely recognized maintainability dimensions'
        $content.QualityMatrix | Should -Match 'Guideline 1 — Write short units of code'
        $content.QualityMatrix | Should -Match 'Guideline 2 — Write simple units of code'
        $content.QualityMatrix | Should -Match 'Guideline 3 — Write code once'
        $content.QualityMatrix | Should -Match 'Guideline 4 — Keep unit interfaces small'
        $content.QualityMatrix | Should -Match 'Guideline 5 — Separate concerns in modules'
        $content.QualityMatrix | Should -Match 'Guideline 6 — Couple architecture components loosely'
        $content.QualityMatrix | Should -Match 'Guideline 7 — Keep architecture components balanced'
        $content.QualityMatrix | Should -Match 'Guideline 8 — Keep your codebase small'
        $content.QualityMatrix | Should -Match 'Guideline 9 — Automate tests'
        $content.QualityMatrix | Should -Match 'Guideline 10 — Write clean code'
        $content.QualityMatrix | Should -Match 'Replace long `switch` blocks or `if`/`elseif` chains with a dispatch hashtable'
        $content.QualityMatrix | Should -Match 'Group related parameters into a single `\[pscustomobject\]`'
        $content.QualityMatrix | Should -Match 'Remove dead code, obsolete private helpers, and commented-out code'
        $content.QualityMatrix | Should -Match 'No broad catches'

        $content.DeveloperSkill | Should -Match 'Nova generates those files under `dist/(NovaModuleTools|\{\{ProjectName\}\})/`'
        $content.DeveloperSkill | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.DeveloperSkill | Should -Match 'short, single-purpose, low-duplication, lightly nested'
        $content.DeveloperSkill | Should -Match 'Keep Nova naming patterns on public commands, and give private helpers clear implementation-focused names'
        $content.DeveloperSkill | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.DeveloperSkill | Should -Match 'do not declare functions inside functions'
        $content.DeveloperSkill | Should -Match 'Grouping two private helpers in one file when both are referenced from outside that file'
        $content.DeveloperSkill | Should -Match 'Before handoff, review every source text file you created or modified under `src/`, `tests/`, `docs/`, and `scripts/` and normalize it to exactly one trailing newline'
        $content.DeveloperSkill | Should -Match 'PowerShell 7\.x-only'
    }

    It 'documents terminal UX guidance in mirrored instructions, skills, and agent entry points' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.TerminalUxInstruction | Should -Match 'Use the `terminal-ux-design` skill'
        $content.TerminalUxInstruction | Should -Match 'Jakob Nielsen'
        $content.TerminalUxInstruction | Should -Match 'Atlassian'

        $content.TerminalUxSkill | Should -Match 'Atlassian''s 10 design principles for delightful CLIs'
        $content.TerminalUxSkill | Should -Match 'Jakob Nielsen''s 10 usability heuristics for user interface design'
        $content.TerminalUxSkill | Should -Match 'This skill applies even when the surface is not named "CLI"'
        $content.TerminalUxSkill | Should -Match 'Combined mapping table'
        $content.TerminalUxSkill | Should -Match 'Two surfaces, two conventions'
        $content.TerminalUxSkill | Should -Match 'Keep PowerShell cmdlet UX and CLI UX distinct'

        $content.Instruction | Should -Match 'terminal-ux-design'
        $content.Instruction | Should -Match 'Terminal UX: `\.github/instructions/terminal-ux-design\.instructions\.md` \+ `terminal-ux-design` skill'
        $content.ArchitectAgent | Should -Match '/terminal-ux-design'
        $content.DeveloperAgent | Should -Match '/terminal-ux-design'
        $content.ReviewerAgent | Should -Match '/terminal-ux-design'
        $content.Agents | Should -Match 'terminal-ux-design'
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
        $content.PlatyPsHelp | Should -Match 'matching command-help file in the same change'
        $content.PlatyPsHelp | Should -Match 'SYNOPSIS`, `SYNTAX`, optional `ALIASES`, `DESCRIPTION`, `EXAMPLES`, `PARAMETERS`, `INPUTS`, `OUTPUTS`, required `NOTES`, and required `RELATED LINKS`'

        $content.DeveloperSkill | Should -Match 'valid PlatyPS-compatible help'
        $content.DeveloperSkill | Should -Match 'New-MarkdownCommandHelp'
        $content.DeveloperSkill | Should -Match 'matching help file immediately in the same change'
        $content.DeveloperSkill | Should -Match 'writing plain Markdown'
        $content.DeveloperAgent | Should -Match 'valid PlatyPS-compatible help docs'
        $content.DeveloperAgent | Should -Match 'matching help file in the same change'
        $content.DeveloperAgent | Should -Match 'New-MarkdownCommandHelp'
        $content.ReviewerAgent | Should -Match 'matching help file in the same change'
        $content.ReviewerAgent | Should -Match 'Test-MarkdownCommandHelp'
        $content.ImplementPrompt | Should -Match 'valid PlatyPS-compatible help under `docs/(NovaModuleTools|\{\{ProjectName\}\})/en-US/`'
        $content.ImplementPrompt | Should -Match 'matching help file immediately in the same change'
        $content.ImplementPrompt | Should -Match 'New-MarkdownCommandHelp'
        $content.ReviewPrompt | Should -Match 'matching help file'
        $content.ReviewPrompt | Should -Match 'New-MarkdownCommandHelp'

        $content.Contributing | Should -Match 'create its matching help file in the same change'
        $content.Contributing | Should -Match 'New-MarkdownCommandHelp'
        $content.Readme | Should -Match 'matching help file in the same change'
        $content.Readme | Should -Match 'New-MarkdownCommandHelp'
    }

    It 'documents Nova-managed project test guidance' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.RepositoryConventions | Should -Match 'test validation: `Invoke-NovaTest` for unit-test validation, then `Test-NovaBuild` for build-validation integration coverage'
        $content.RepositoryConventions | Should -Match 'local quality loop: use the repository quality wrapper when one exists; otherwise run ScriptAnalyzer, build, `Invoke-NovaTest`, and `Test-NovaBuild` in the documented project order'
        $content.RepositoryConventions | Should -Not -Match 'Invoke-Pester -Path'

        $content.TestingPolicy | Should -Match '`Invoke-NovaTest` is the unit-test entrypoint and `Test-NovaBuild` is the build-validation integration-test entrypoint'
        $content.TestingPolicy | Should -Match 'Integration tests may import `dist/`'
        $content.TestingPolicy | Should -Match '\*\.Integration\.Tests\.ps1'
        $content.TestingPolicy | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.TestingPolicy | Should -Match '-WhatIf'
        $content.TestingPolicy | Should -Match 'Do not validate with direct `Invoke-Pester`'
        $content.TestingPolicy | Should -Match 'normal path and every distinct failure mode and boundary condition visible in the changed code''s branching logic'
        $content.TestingPolicy | Should -Match 'mocks or stubs'
        $content.TestingPolicy | Should -Match 'isolated and order-independent'
        $content.TestingPolicy | Should -Not -Match 'Invoke-Pester -Path'

        $content.PesterSkill | Should -Match 'Invoke-NovaTest'
        $content.PesterSkill | Should -Match 'Test-NovaBuild'
        $content.PesterSkill | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.PesterSkill | Should -Match 'Do not validate with direct `Invoke-Pester`'
        $content.PesterSkill | Should -Match 'normal, boundary, and unhappy paths'
        $content.PesterSkill | Should -Match 'mocks/stubs'
        $content.PesterSkill | Should -Not -Match 'Invoke-Pester -Path'

        $content.DeveloperSkill | Should -Match 'Run `Invoke-NovaTest` for any change under `src/` or `tests/`'
        $content.DeveloperSkill | Should -Match 'Run `Test-NovaBuild` additionally when a public command signature changed, packaging or manifest metadata changed, or integration tests were added or modified'
        $content.DeveloperSkill | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.DeveloperSkill | Should -Match '-WhatIf'
        $content.DeveloperAgent | Should -Match 'Validate Nova-managed project tests through `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration validation'
        $content.DeveloperAgent | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.DeveloperAgent | Should -Match '-WhatIf'
        $content.TestEngineerAgent | Should -Match 'Use `Invoke-NovaTest` as the unit-test entrypoint and `Test-NovaBuild` as the build-validation integration-test entrypoint'
        $content.TestEngineerAgent | Should -Match 'testing-policy\.instructions\.md'
        $content.ReviewerAgent | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.ReviewerAgent | Should -Match 'bypasses `Invoke-NovaTest` or `Test-NovaBuild` with direct `Invoke-Pester`'
        $content.ImplementPrompt | Should -Match 'Validate Nova-managed project tests through `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration validation'
        $content.ImplementPrompt | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.ImplementPrompt | Should -Match '-WhatIf'
        $content.ReviewPrompt | Should -Match 'bypasses `Invoke-NovaTest` or `Test-NovaBuild` with direct `Invoke-Pester`'
        $content.ImproveCoveragePrompt | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.ImproveCoveragePrompt | Should -Match '-WhatIf'

        $content.Contributing | Should -Match 'use `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration runs'
        $content.Contributing | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.Readme | Should -Match 'Use `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration runs'
        $content.Readme | Should -Match 'tests/public/<Command>\.Integration\.Tests\.ps1'
        $content.Readme | Should -Match '-WhatIf'
    }

    It 'documents proper PSScriptAnalyzer usage guidance' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.ScriptAnalyzer | Should -Match 'PSScriptAnalyzer is the supported static analyzer'
        $content.ScriptAnalyzer | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.ScriptAnalyzer | Should -Match 'Invoke-ScriptAnalyzer'
        $content.ScriptAnalyzer | Should -Match 'use `-Settings` with the repository-approved settings source'
        $content.ScriptAnalyzer | Should -Match 'Invoke-ScriptAnalyzer -Fix'
        $content.ScriptAnalyzer | Should -Match 'EnableExit'

        $content.RepositoryConventions | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'

        $content.DeveloperSkill | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.DeveloperSkill | Should -Match 'Invoke-ScriptAnalyzer'
        $content.DeveloperAgent | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.DeveloperAgent | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.TestEngineerAgent | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.TestingPolicy | Should -Match 'Invoke-ScriptAnalyzerCI\.ps1'
        $content.ReviewerAgent | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.ReviewerAgent | Should -Match 'bypasses repository-approved settings'
        $content.ImplementPrompt | Should -Match 'Prefer `\./scripts/build/Invoke-ScriptAnalyzerCI\.ps1` and the repository quality loop, when present'
        $content.ReviewPrompt | Should -Match 'psscriptanalyzer\.instructions\.md'

        $content.Contributing | Should -Match 'psscriptanalyzer\.instructions\.md'
        $content.Readme | Should -Match 'psscriptanalyzer\.instructions\.md'
    }

    It 'documents run.ps1 only as a repository quality-loop entrypoint in generated starter guidance' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.DeveloperAgent | Should -Match '\./run\.ps1` or `\./scripts/build/Invoke-ScriptAnalyzerCI\.ps1'
        $content.ImplementPrompt | Should -Match 'if `run\.ps1` or `Invoke-ScriptAnalyzerCI\.ps1` reports ScriptAnalyzer findings'
        $content.QualityMatrix | Should -Match '`run\.ps1`, `reload\.ps1`, and similar entry scripts'
        $content.ScriptAnalyzer | Should -Match 'then `\./run\.ps1` before opening a pull request'
        $content.CodingStandards | Should -Match 'In `run\.ps1` and any task script that runs the full quality pipeline'
        $content.DeveloperSkill | Should -Match 'Always run `pwsh -NoLogo -NoProfile -File \./run\.ps1` as the final gate before handoff'
    }

    It 'documents agent and starter expectations consistently' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.DeveloperAgent | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.DeveloperAgent | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.DeveloperAgent | Should -Match 'must not declare nested functions'
        $content.DeveloperAgent | Should -Match 'tests/private/<domain>/<Helper>\.Tests\.ps1'
        $content.DeveloperAgent | Should -Match 'Public/private file ownership still follows the one externally called function per file rule'
        $content.DeveloperAgent | Should -Match 'Every changed or generated text file has been checked and ends with exactly one trailing newline and no extra blank lines at the bottom'

        $content.TestEngineerAgent | Should -Match 'testing-policy\.instructions\.md'
        $content.TestEngineerAgent | Should -Match 'use direct `Invoke-ScriptAnalyzer` only for focused local investigation that reuses the repository-approved settings from that wrapper'
        $content.ReviewerAgent | Should -Match 'Flag public files that do not keep exactly one top-level function'
        $content.ReviewerAgent | Should -Match 'flag any private file whose secondary functions are called from outside that file'
        $content.ReviewerAgent | Should -Match 'flag nested function declarations inside PowerShell functions'
        $content.ReviewerAgent | Should -Match 'code-quality-matrix\.instructions\.md'
        $content.ReviewerAgent | Should -Match 'If any referenced `\.github/instructions/` or `\.github/skills/` file is not available in context, stop and report which file is missing before continuing'
        $content.ReviewerAgent | Should -Match 'outside `src/`, `tests/`, `docs/`, `\.github/`, and `AGENTS\.md`'
        $content.ReviewPrompt | Should -Match 'If a referenced instructions or skills file cannot be read, stop and report which file is missing before continuing'

        $content.ReleaseManagerAgent | Should -Match 'Required skill markdown-authoring could not be loaded\. Please resolve this before continuing\.'
        $content.PrepareReleasePrompt | Should -Match 'Required skill \[name\] could not be loaded\. Please resolve this before continuing\.'

        $content.Contributing | Should -Match 'keep one externally called function per file and match the file name to that function'
        $content.Contributing | Should -Match 'must not declare nested functions inside their bodies'
        $content.Contributing | Should -Match 'TextFileFormatting\.Tests\.ps1'
        $content.Contributing | Should -Match 'make every changed or generated text file end immediately after exactly one newline terminator with no blank spacer line at the bottom'

        $content.Readme | Should -Match 'ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Invoke-NovaTest`, then `Test-NovaBuild`'
        $content.Readme | Should -Match 'If the repository quality loop or `Invoke-ScriptAnalyzerCI\.ps1` reports ScriptAnalyzer findings, fix them before review or handoff'
        $content.Readme | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $content.Readme | Should -Match 'must not declare nested functions inside their bodies'
        $content.Readme | Should -Match 'Test-TextFileFormatting\.ps1'
        $content.Readme | Should -Match 'Make every changed or generated text file end immediately after exactly one newline terminator; do not leave a blank spacer line at the bottom'
        $content.Readme | Should -Match 'If it is `5\.1`, do not introduce PowerShell 7\.x-only features'
        $content.Readme | Should -Match 'every new or changed `src/\*\*/\*\.ps1` file should have one focused `\.Tests\.ps1` file'
    }

    It 'generates AGENTS.md as a mirror of copilot-instructions.md with a do-not-edit banner' {
        $content = & $script:getAgenticScaffoldGuidanceContent

        $content.Agents | Should -Match 'Generated from \.github/copilot-instructions\.md by scripts/build/Sync-AgenticCopilotScaffold\.ps1\. Do not edit by hand\.'
        $content.Agents | Should -Match 'Copilot instructions'
        $content.Agents | Should -Match 'Task map'
        $content.Agents | Should -Match 'repository-conventions\.instructions\.md'
    }
}
