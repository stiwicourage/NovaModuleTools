BeforeAll {
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/build/Test-TextFileFormatting.ps1')
}

Describe 'Repository text file formatting' {
    It 'keeps tracked text files on exactly one trailing newline with no extra blank lines at the bottom' {
        $projectRoot = Split-Path -Parent $PSScriptRoot
        $result = Test-TextFileFormatting -ProjectRoot $projectRoot
        $because = if ($result.IsValid) {
            'all tracked text files should comply with the repository file-ending rule'
        } else {
            "violations: $( $result.Violations -join ', ' )"
        }

        $result.IsValid | Should -BeTrue -Because $because
    }
}
