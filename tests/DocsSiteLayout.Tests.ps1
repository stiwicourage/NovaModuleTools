BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:siteCssPath = Join-Path $script:repoRoot 'docs/assets/site.css'
    $script:siteCssContent = Get-Content -LiteralPath $script:siteCssPath -Raw
    $script:getHtmlContent = {
        param([Parameter(Mandatory)][string]$RelativePath)

        return Get-Content -LiteralPath (Join-Path $script:repoRoot $RelativePath) -Raw
    }
}

Describe 'docs site layout guardrails' {
    It 'keeps wide-screen layout and text containers uncapped in the shared stylesheet' {
        $script:siteCssContent | Should -Match '(?s):root\s*\{.*?--max-width:\s*1600px;'
        $script:siteCssContent | Should -Match '(?s)\.guide-hero\s*\{.*?max-width:\s*none;'
        $script:siteCssContent | Should -Match '(?s)\.guide-content\s+\.content-section\s*>\s*p,\s*\.guide-content\s+\.content-section\s*>\s*ul,\s*\.guide-content\s+\.content-section\s*>\s*ol\s*\{.*?max-width:\s*none;'
        $script:siteCssContent | Should -Match '(?s)h1\s*\{.*?max-width:\s*none;'
        $script:siteCssContent | Should -Match '(?s)\.lead\s*\{.*?max-width:\s*none;'
        $script:siteCssContent | Should -Match '(?s)\.narrow\s*\{.*?max-width:\s*none;'
        $script:siteCssContent | Should -Match '(?s)\.section-heading\s*\{.*?max-width:\s*none;'
    }

    It 'keeps key docs pages on the shared text-width wrappers that the stylesheet protects' {
        $gettingStartedPage = & $script:getHtmlContent -RelativePath 'docs/getting-started.html'
        $indexPage = & $script:getHtmlContent -RelativePath 'docs/index.html'

        $gettingStartedPage | Should -Match '<main class="page-shell">'
        $gettingStartedPage | Should -Match '<section class="guide-hero">'
        $gettingStartedPage | Should -Match '<p class="lead">'

        $indexPage | Should -Match '<header class="hero">'
        $indexPage | Should -Match '<p class="lead">'
        $indexPage | Should -Match 'class="section__inner narrow"'
        $indexPage | Should -Match 'class="section-heading"'
    }

    It 'keeps the commands page starter card balanced for cheat-sheet use' {
        $commandsPage = & $script:getHtmlContent -RelativePath 'docs/commands.html'

        $commandsPage | Should -Match '<li><a href="#setup-and-project">Set up a project</a></li>'
        $commandsPage | Should -Match '<h2>Set up a project</h2>'
        $commandsPage | Should -Match '<div class="command-card-grid command-card-grid--stacked">'
        $script:siteCssContent | Should -Match '(?s)\.command-card-grid--stacked\s*\{.*?grid-template-columns:\s*1fr;'
        $commandsPage | Should -Match '<li><strong>Includes:</strong> a pre-question Nova release warning'
        $commandsPage | Should -Match '<li><strong>Optional:</strong> add the <strong>Agentic Copilot</strong> starter package'
        $commandsPage | Should -Not -Match 'valid-PlatyPS help guidance'
        $commandsPage | Should -Not -Match 'source/helper-script maintainability guidance'
    }

    It 'keeps Agentic Copilot bold everywhere on the site' {
        $sitePages = Get-ChildItem -LiteralPath (Join-Path $script:repoRoot 'docs') -Filter '*.html' -File

        foreach ($page in $sitePages) {
            $content = Get-Content -LiteralPath $page.FullName -Raw
            $plainMentions = $content -replace '<strong>Agentic Copilot</strong>', ''

            $plainMentions | Should -Not -Match 'Agentic Copilot' -Because $page.Name
        }
    }

    It 'keeps the getting-started Agentic quickstart copy split into readable paragraphs' {
        $gettingStartedPage = & $script:getHtmlContent -RelativePath 'docs/getting-started.html'

        $gettingStartedPage | Should -Match '(?s)optional <strong>Agentic Copilot</strong> starter package\.</p>\s*<p>The starting version prompt now defaults to <code>0\.1\.0-preview</code>'
        $gettingStartedPage | Should -Match '(?s)ignored\s+without overwriting existing ignore\s*rules\.</p>\s*<p>The Agentic package follows Nova''s maintained agentic guidance'
        $gettingStartedPage | Should -Match '(?s)changed or generated text files\.</p>\s*<p>Nova then creates a project folder under the path you selected\.</p>'
    }

    It 'keeps the core-workflows scaffold explanation split into readable paragraphs' {
        $coreWorkflowsPage = & $script:getHtmlContent -RelativePath 'docs/core-workflows.html'

        $coreWorkflowsPage | Should -Match '(?s)optional\s*<strong>Agentic Copilot</strong> starter package after the Git prompt\.</p>\s*<p>The starting version prompt now defaults to\s*<code>0\.1\.0-preview</code>'
        $coreWorkflowsPage | Should -Match '(?s)artifact paths are ignored\s+without overwriting existing rules\.</p>\s*<p>The Agentic prompt defaults to <code>No</code>'
        $coreWorkflowsPage | Should -Match '(?s)changed or generated text files\.</p>\s*<p>The generated <code>project\.json</code> also starts with Nova''s standard <code>Pester</code>'
    }

}
