BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:agentsDir = Join-Path $script:repoRoot '.github/agents'
    $script:skillsDir = Join-Path $script:repoRoot '.github/skills'
    $script:promptsDir = Join-Path $script:repoRoot '.github/prompts'
    $script:instructionsDir = Join-Path $script:repoRoot '.github/instructions'

    function Get-SkillReferenceList {
        param([Parameter(Mandatory)][string]$Content)

        $matches = [System.Text.RegularExpressions.Regex]::Matches($Content, '(?m)^\s*-\s+`?/([a-z][a-z0-9-]+)`?')
        return @($matches | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    }

    function Get-AgentReferenceList {
        param([Parameter(Mandatory)][string]$Content)

        $matches = [System.Text.RegularExpressions.Regex]::Matches($Content, '`([a-z][a-z0-9-]+)\.agent\.md`')
        $bareMatches = [System.Text.RegularExpressions.Regex]::Matches($Content, '`([a-z][a-z0-9-]+)`\s+agent')
        $all = @($matches | ForEach-Object { $_.Groups[1].Value }) + @($bareMatches | ForEach-Object { $_.Groups[1].Value })
        return @($all | Sort-Object -Unique)
    }

    function Get-FrontMatterApplyTo {
        param([Parameter(Mandatory)][string]$Content)

        if ($Content -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
            $frontMatter = $matches[1]
            if ($frontMatter -match '(?m)^applyTo:\s*"?([^"\r\n]+?)"?\s*$') {
                return $matches[1].Trim()
            }
        }
        return $null
    }
}

Describe 'Agentic Copilot wire-up integrity' {
    It 'resolves every /skill-name referenced by an agent file to an existing skill folder' {
        $brokenReferences = [System.Collections.Generic.List[string]]::new()

        $agentFiles = Get-ChildItem -LiteralPath $script:agentsDir -Filter '*.agent.md' -File
        foreach ($agent in $agentFiles) {
            $content = Get-Content -LiteralPath $agent.FullName -Raw
            $skillNames = Get-SkillReferenceList -Content $content
            foreach ($skillName in $skillNames) {
                $skillPath = Join-Path $script:skillsDir "$skillName/SKILL.md"
                if (-not (Test-Path -LiteralPath $skillPath)) {
                    $brokenReferences.Add("$($agent.Name) -> /$skillName (expected $skillPath)") | Out-Null
                }
            }
        }

        $brokenReferences | Should -BeNullOrEmpty
    }

    It 'resolves every agent referenced by a prompt to an existing agent file' {
        $brokenReferences = [System.Collections.Generic.List[string]]::new()

        $promptFiles = Get-ChildItem -LiteralPath $script:promptsDir -Filter '*.prompt.md' -File
        foreach ($prompt in $promptFiles) {
            $content = Get-Content -LiteralPath $prompt.FullName -Raw
            $agentNames = Get-AgentReferenceList -Content $content
            foreach ($agentName in $agentNames) {
                $agentPath = Join-Path $script:agentsDir "$agentName.agent.md"
                if (-not (Test-Path -LiteralPath $agentPath)) {
                    $brokenReferences.Add("$($prompt.Name) -> $agentName (expected $agentPath)") | Out-Null
                }
            }
        }

        $brokenReferences | Should -BeNullOrEmpty
    }

    It 'gives every instruction file a non-empty applyTo: front-matter glob' {
        $missing = [System.Collections.Generic.List[string]]::new()

        $instructionFiles = Get-ChildItem -LiteralPath $script:instructionsDir -Filter '*.instructions.md' -File
        foreach ($instruction in $instructionFiles) {
            $content = Get-Content -LiteralPath $instruction.FullName -Raw
            $applyTo = Get-FrontMatterApplyTo -Content $content
            if ([string]::IsNullOrWhiteSpace($applyTo)) {
                $missing.Add($instruction.Name) | Out-Null
            }
        }

        $missing | Should -BeNullOrEmpty
    }

    It 'gives every skill folder a SKILL.md whose name field matches the folder name' {
        $mismatched = [System.Collections.Generic.List[string]]::new()

        $skillFolders = Get-ChildItem -LiteralPath $script:skillsDir -Directory
        foreach ($folder in $skillFolders) {
            $skillFile = Join-Path $folder.FullName 'SKILL.md'
            if (-not (Test-Path -LiteralPath $skillFile)) {
                $mismatched.Add("$($folder.Name): SKILL.md missing") | Out-Null
                continue
            }
            $content = Get-Content -LiteralPath $skillFile -Raw
            if ($content -notmatch '(?m)^name:\s*([a-z0-9-]+)\s*$') {
                $mismatched.Add("$($folder.Name): no name: field") | Out-Null
                continue
            }
            if ($matches[1] -ne $folder.Name) {
                $mismatched.Add("$($folder.Name): name field is '$($matches[1])'") | Out-Null
            }
        }

        $mismatched | Should -BeNullOrEmpty
    }
}
