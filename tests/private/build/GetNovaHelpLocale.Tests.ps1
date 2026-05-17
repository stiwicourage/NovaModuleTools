BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetNovaHelpLocale.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'Get-NovaHelpLocale' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:root -Force
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns the locale parsed from the help file' {
        $file = Join-Path $script:root 'a.md'
        Set-Content -LiteralPath $file -Value @('Locale: en-US', '')
        $info = Get-Item -LiteralPath $file

        Get-NovaHelpLocale -HelpMarkdownFiles @($info) | Should -Be 'en-US'
    }

    It 'returns en-US default when no locale line is found' {
        $file = Join-Path $script:root 'a.md'
        Set-Content -LiteralPath $file -Value 'no metadata here'
        $info = Get-Item -LiteralPath $file

        Get-NovaHelpLocale -HelpMarkdownFiles @($info) | Should -Be 'en-US'
    }

    It 'throws when files declare conflicting locales' {
        $a = Join-Path $script:root 'a.md'
        $b = Join-Path $script:root 'b.md'
        Set-Content -LiteralPath $a -Value 'Locale: en-US'
        Set-Content -LiteralPath $b -Value 'Locale: da-DK'

        {Get-NovaHelpLocale -HelpMarkdownFiles @((Get-Item $a), (Get-Item $b))} | Should -Throw
    }
}
