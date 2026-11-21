BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:workflowRoot = Join-Path $script:repoRoot '.github/workflows'
    $script:sharedWorkflowPrefix = 'stiwicourage/powershell-ci/.github/workflows/'
    $script:sharedVersion = '0.4.0'

    function Get-WorkflowText {
        param([Parameter(Mandatory)][string]$Name)

        return Get-Content -LiteralPath (Join-Path $script:workflowRoot $Name) -Raw
    }

    function Get-SharedWorkflowReference {
        param([Parameter(Mandatory)][string]$Name)

        return [regex]::Escape("uses: $script:sharedWorkflowPrefix$Name@$script:sharedVersion")
    }
}

Describe 'Shared powershell-ci workflows' {
    It 'runs tests through the shared tests workflow with Nova settings' {
        $text = Get-WorkflowText -Name 'Tests.yml'

        $text | Should -Match (Get-SharedWorkflowReference -Name 'tests.yml')
        $text | Should -Match 'test-isolation: process'
        $text | Should -Match 'changelog-files: \./CHANGELOG\.md \./RELEASE_NOTE\.md'
        $text | Should -Match 'script-analyzer-paths: src scripts run\.ps1'
        $text | Should -Match 'script-analyzer-severity: Error Warning ParseError'
        $text | Should -Match "script-analyzer-required-version: '1\.25\.0'"
        $text | Should -Match 'artifact-name: nova-ci-artifacts'
        $text | Should -Match 'secrets: inherit'
    }

    It 'runs the shared test actions on the <Platform> platform lane' -ForEach @(
        @{ Platform = 'Windows'; Runner = 'windows-2025' }
        @{ Platform = 'Linux'; Runner = 'ubuntu-24.04' }
        @{ Platform = 'macOS'; Runner = 'macos-15' }
    ) {
        $text = Get-WorkflowText -Name 'Run-Platform-Matrix.yml'

        $text | Should -Match "platform: $Platform\s+runner: $Runner"
    }

    It 'runs every platform lane through the pinned shared test actions without analyzer, changelog, or coverage-upload jobs' {
        $text = Get-WorkflowText -Name 'Run-Platform-Matrix.yml'

        $text | Should -Match ([regex]::Escape("uses: stiwicourage/powershell-ci/actions/install-ps-modules@$script:sharedVersion"))
        $text | Should -Match ([regex]::Escape("uses: stiwicourage/powershell-ci/actions/nova-test@$script:sharedVersion"))
        $text | Should -Match 'fail-fast: false'
        $text | Should -Match 'runs-on: \$\{\{ matrix\.runner \}\}'
        $text | Should -Match 'test-isolation: process'
        $text | Should -Match 'name: nova-platform-\$\{\{ matrix\.platform \}\}'
        $text | Should -Not -Match '\.github/workflows/tests\.yml'
        $text | Should -Not -Match '(?i)codescene'
        $text | Should -Not -Match 'secrets:'
    }

    It 'publishes through the shared publish workflow with build validation tests' {
        $text = Get-WorkflowText -Name 'Publish.yml'

        $text | Should -Match (Get-SharedWorkflowReference -Name 'publish.yml')
        $text | Should -Match 'test-command: Test-NovaBuild'
        $text | Should -Match 'secrets: inherit'
    }

    It 'runs security scans through the shared security workflows' -ForEach @(
        @{ Name = 'codeql.yml' }
        @{ Name = 'powershell-analyzer.yml' }
        @{ Name = 'dependency-review.yml' }
    ) {
        Get-WorkflowText -Name 'Security.yml' | Should -Match (Get-SharedWorkflowReference -Name $Name)
    }

    It 'keeps no repository-owned copies of the shared CI implementation' -ForEach @(
        @{ RelativePath = '.github/actions' }
        @{ RelativePath = 'scripts/build/ci' }
        @{ RelativePath = '.github/workflows/powershell.yml' }
        @{ RelativePath = '.github/workflows/dependency-review.yml' }
    ) {
        Join-Path $script:repoRoot $RelativePath | Should -Not -Exist
    }
}
