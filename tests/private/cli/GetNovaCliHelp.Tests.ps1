BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliHelp.ps1')

    function Get-ResourceFilePath {param([string]$FileName) return "/tmp/cli-help-$([guid]::NewGuid()).txt"}
}

Describe 'Get-NovaCliHelp' {
    It 'reads the resolved CLI help file content' {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            Set-Content -LiteralPath $tempFile -Value 'help-body' -NoNewline
            Mock Get-ResourceFilePath {return $tempFile} -ParameterFilter {$FileName -eq 'cli/NovaCliHelp.txt'}
            Get-NovaCliHelp | Should -Be 'help-body'
        } finally {
            Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
        }
    }
}
