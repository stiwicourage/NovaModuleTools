BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliCommandHelpDefinition.ps1')

    function Get-ResourceFilePath {param([string]$FileName) return $FileName}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaCliHelpCommandNameList' {
    It 'returns the known CLI command names' {
        $names = Get-NovaCliHelpCommandNameList
        $names | Should -Contain 'init'
        $names | Should -Contain 'release'
        $names | Should -Contain 'notification'
    }
}

Describe 'Get-NovaCliCommandHelpFilePath' {
    It 'composes the cli/help resource path' {
        Get-NovaCliCommandHelpFilePath -Command 'build' | Should -Be 'cli/help/build.psd1'
    }
}

Describe 'Get-NovaCliCommandHelpDefinition' {
    It 'throws for unknown commands' {
        {Get-NovaCliCommandHelpDefinition -Command 'unknown-cmd'} | Should -Throw '*Unknown command*'
    }

    It 'imports the .psd1 definition when the command is known' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        $file = Join-Path $tempDir 'init.psd1'
        Set-Content -LiteralPath $file -Value "@{Summary = 'init help'}"
        try {
            Mock Get-ResourceFilePath {return $file}
            (Get-NovaCliCommandHelpDefinition -Command 'init').Summary | Should -Be 'init help'
        } finally {
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
