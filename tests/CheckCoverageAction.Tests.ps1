BeforeAll {
    $script:actionPath = Join-Path $PSScriptRoot '..' '.github' 'actions' 'check-coverage' 'action.yml'
    $script:actionContent = Get-Content -LiteralPath $script:actionPath -Raw
}

Describe 'check-coverage action' {
    It 'normalizes JaCoCo coverage paths before running the gate check' {
        $script:actionContent | Should -Match 'Normalize JaCoCo coverage paths'
        $script:actionContent | Should -Match 'Repair-CodeSceneJaCoCoCoverage\.ps1'
    }

    It 'keeps the gate check on the configured coverage glob' {
        $script:actionContent | Should -Match 'cs-coverage"\s+check\s+--verbose\s+--coverage-files\s+"\$\{\{\s*inputs\.coverage-files\s*\}\}"'
    }
}
