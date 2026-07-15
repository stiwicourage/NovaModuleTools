BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:runScriptPath = Join-Path $script:repoRoot 'run.ps1'
}

Describe 'run.ps1 quality loop' {
    It 'runs Invoke-NovaTest and Test-NovaBuild through fresh child pwsh sessions' {
        $content = Get-Content -LiteralPath $script:runScriptPath -Raw

        $content.Contains('function Invoke-NovaFreshValidationCommand') | Should -BeTrue
        $content.Contains('& pwsh -NoLogo -NoProfile -Command $Command') | Should -BeTrue
        $content.Contains('Invoke-NovaFreshValidationCommand -Command "Import-Module ''$builtModulePath'' -Force -ErrorAction Stop; Invoke-NovaTest"') | Should -BeTrue
        $content.Contains('Invoke-NovaFreshValidationCommand -Command "Import-Module ''$builtModulePath'' -Force -ErrorAction Stop; Test-NovaBuild"') | Should -BeTrue
    }
}


