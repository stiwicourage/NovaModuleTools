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

    It 'documents Nova-managed project expectations in the starter guidance' {
        $instructionContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/copilot-instructions.md') -Raw
        $codingStandardsContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/powershell-coding-standards.instructions.md') -Raw
        $developerAgentContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/powershell-developer.agent.md') -Raw
        $reviewerAgentContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/agents/reviewer.agent.md') -Raw
        $developerSkillContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/powershell-module-development/SKILL.md') -Raw
        $implementPromptContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/prompts/implement-issue.prompt.md') -Raw
        $testingPolicyContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/testing-policy.instructions.md') -Raw
        $agentsContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'AGENTS.md') -Raw
        $contributingContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'CONTRIBUTING.md') -Raw
        $readmeContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'README.md') -Raw

        $instructionContent | Should -Match 'Do not create or maintain hand-written module `\.psm1` or module `\.psd1` files in source'
        $instructionContent | Should -Match 'Manifest\.PowerShellHostVersion'
        $instructionContent | Should -Match 'src/private/` files should expose at most one externally called function per file'
        $instructionContent | Should -Match 'file name should match the function that owns the file'
        $instructionContent | Should -Match 'review every changed or created text file and ensure it ends with exactly one trailing newline and no extra blank lines at the bottom'
        $codingStandardsContent | Should -Match 'Invoke-\{\{ShortName\}\}\*'
        $codingStandardsContent | Should -Match 'Match the file name to that top-level public function name'
        $codingStandardsContent | Should -Match 'In `src/private/`, keep at most one externally called function per file and match the file name to that entry function'
        $codingStandardsContent | Should -Match 'If two private functions are both called from outside their file, split them into separate same-named files'
        $codingStandardsContent | Should -Match 'Every changed or generated text file, including `\.ps1` files, must end with exactly one trailing newline and no extra blank lines at the bottom'
        $developerAgentContent | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $developerAgentContent | Should -Match 'Public/private file ownership still follows the one externally called function per file rule'
        $developerAgentContent | Should -Match 'Every changed or generated text file has been checked and ends with exactly one trailing newline and no extra blank lines at the bottom'
        $developerSkillContent | Should -Match 'Nova generates those files under `dist/\{\{ProjectName\}\}/`'
        $developerSkillContent | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $developerSkillContent | Should -Match 'Grouping two externally called private helpers in one file'
        $developerSkillContent | Should -Match 'Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline'
        $developerSkillContent | Should -Match 'PowerShell 7\.x-only'
        $reviewerAgentContent | Should -Match 'Flag public files that do not keep exactly one top-level function'
        $reviewerAgentContent | Should -Match 'flag private files that group multiple externally called functions'
        $implementPromptContent | Should -Match 'Keep file/function ownership explicit: one externally called function per file'
        $instructionContent | Should -Match 'docs/\{\{ProjectName\}\}/en-US/'
        $instructionContent | Should -Match 'Do not exclude or suppress PSScriptAnalyzer rules'
        $instructionContent | Should -Match 'If `run\.ps1` or `\./scripts/build/Invoke-ScriptAnalyzerCI\.ps1` reports ScriptAnalyzer findings, fix them before review, handoff, or commit'
        $testingPolicyContent | Should -Match 'Manifest\.PowerShellHostVersion'
        $agentsContent | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $contributingContent | Should -Match 'keep one externally called function per file and match the file name to that function'
        $agentsContent | Should -Match 'End every changed or generated text file with exactly one trailing newline and no extra blank lines at the bottom'
        $contributingContent | Should -Match 'make every changed or generated text file end with exactly one trailing newline and no extra blank lines at the bottom'
        $readmeContent | Should -Match 'ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`'
        $readmeContent | Should -Match 'If `run\.ps1` or `Invoke-ScriptAnalyzerCI\.ps1` reports ScriptAnalyzer findings, fix them before review or handoff'
        $readmeContent | Should -Match 'Keep one externally called function per file and match the file name to that function'
        $readmeContent | Should -Match 'Make every changed or generated text file end with exactly one trailing newline and no extra blank lines at the bottom before handoff'
        $testingPolicyContent | Should -Match 'For every new or changed `src/\*\*/\*\.ps1` file'
        $testingPolicyContent | Should -Match 'Source-mirrored tests should use'
        $readmeContent | Should -Match 'If it is `5\.1`, do not introduce PowerShell 7\.x-only features'
        $readmeContent | Should -Match 'every new or changed `src/\*\*/\*\.ps1` file should have one focused `\.Tests\.ps1` file'
    }
}
