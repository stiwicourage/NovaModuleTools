BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:runScriptPath = (Resolve-Path -LiteralPath (Join-Path $script:repoRoot 'run.ps1')).Path
    $script:runScriptContent = Get-Content -LiteralPath $script:runScriptPath -Raw -ErrorAction Stop
}

Describe 'run.ps1 quality loop' {
    It 'runs Invoke-NovaTest and Test-NovaBuild through fresh child pwsh sessions' {
        $script:runScriptContent | Should -Not -BeNullOrEmpty

        $script:runScriptContent.Contains('function Invoke-NovaFreshValidationCommand') | Should -BeTrue
        $script:runScriptContent.Contains('& pwsh -NoLogo -NoProfile -Command $Command') | Should -BeTrue
        $script:runScriptContent.Contains('Invoke-NovaFreshValidationCommand -Command "Import-Module ''$builtModulePath'' -Force -ErrorAction Stop; Invoke-NovaTest"') | Should -BeTrue
        $script:runScriptContent.Contains('Invoke-NovaFreshValidationCommand -Command "Import-Module ''$builtModulePath'' -Force -ErrorAction Stop; Test-NovaBuild"') | Should -BeTrue
    }
}

