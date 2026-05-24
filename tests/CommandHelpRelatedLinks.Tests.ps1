BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $script:docsDirectory = Join-Path $projectRoot 'docs/NovaModuleTools/en-US'
    $script:helpFiles = Get-ChildItem -LiteralPath $script:docsDirectory -Filter '*.md' -File |
        Where-Object Name -ne 'NovaModuleTools.md'

    $script:relatedLinks = foreach ($file in $script:helpFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $sectionMatch = [regex]::Match($content, '(?ms)^## RELATED LINKS\r?\n\r?\n(?<body>.*)$')
        if (-not $sectionMatch.Success) {
            continue
        }

        $linkLineList = @(
            $sectionMatch.Groups['body'].Value -split '\r?\n' |
                Where-Object { $_ -match '^- ' }
        )

        foreach ($line in $linkLineList) {
            $lineMatch = [regex]::Match($line, '^- \[(?<text>[^\]]+)\]\((?<uri>[^)]+)\)$')
            [pscustomobject]@{
                FileName = $file.Name
                Line = $line
                Text = $lineMatch.Groups['text'].Value
                Uri = $lineMatch.Groups['uri'].Value
                IsMarkdownLink = $lineMatch.Success
            }
        }
    }
}

Describe 'command help related links' {
    It 'uses Markdown link syntax for every related-links entry' {
        foreach ($entry in $script:relatedLinks) {
            $entry.Line | Should -Match '^- \[[^\]]+\]\([^)]+\)$' -Because $entry.FileName
        }
    }

    It 'does not use GitHub blob links in related-links entries' {
        foreach ($entry in $script:relatedLinks) {
            $entry.Line | Should -Not -Match 'github\.com/.*/blob/' -Because $entry.FileName
        }
    }

    It 'uses resolvable internal help links or Nova website links in related-links entries' {
        foreach ($entry in $script:relatedLinks) {
            $entry.IsMarkdownLink | Should -BeTrue -Because $entry.FileName

            if ($entry.Uri -match '^\./(?<target>[^/]+\.md)$') {
                $targetPath = Join-Path $script:docsDirectory $Matches['target']
                (Test-Path -LiteralPath $targetPath -PathType Leaf) | Should -BeTrue -Because "$($entry.FileName): $($entry.Uri)"
                continue
            }

            $entry.Uri | Should -Match '^https://www\.novamoduletools\.com/' -Because "$($entry.FileName): $($entry.Uri)"
        }
    }
}
