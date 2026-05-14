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
        $developerSkillContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/skills/powershell-module-development/SKILL.md') -Raw
        $testingPolicyContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot '.github/instructions/testing-policy.instructions.md') -Raw
        $readmeContent = Get-Content -LiteralPath (Join-Path $script:scaffoldRoot 'README.md') -Raw

        $instructionContent | Should -Match 'Do not create or maintain hand-written module `\.psm1` or module `\.psd1` files in source'
        $developerSkillContent | Should -Match 'Nova generates those files under `dist/\{\{ProjectName\}\}/`'
        $instructionContent | Should -Match 'docs/\{\{ProjectName\}\}/en-US/'
        $testingPolicyContent | Should -Match 'For every new or changed `src/\*\*/\*\.ps1` file'
        $testingPolicyContent | Should -Match 'Source-mirrored tests should use'
        $readmeContent | Should -Match 'every new or changed `src/\*\*/\*\.ps1` file should have one focused `\.Tests\.ps1` file'
    }
}
