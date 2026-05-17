BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/FormatNovaCliCommandHelp.ps1')

    function New-TestOption {
        param([string]$Short, [string]$Long, [string]$Placeholder = '', [string]$Description = '')
        return @{Short=$Short; Long=$Long; Placeholder=$Placeholder; Description=$Description}
    }
}

Describe 'Get-NovaCliHelpText' {
    It 'joins lines with newline and trims trailing whitespace' {
        Get-NovaCliHelpText -Lines @('a','b','') | Should -Be ("a" + [Environment]::NewLine + "b")
    }
}

Describe 'Get-NovaCliHelpOptionLabel' {
    It 'omits placeholder when empty' {
        Get-NovaCliHelpOptionLabel -Option (New-TestOption -Short '-h' -Long '--help') | Should -Be '-h, --help'
    }
    It 'includes placeholder when set' {
        Get-NovaCliHelpOptionLabel -Option (New-TestOption -Short '-p' -Long '--path' -Placeholder '<PATH>') | Should -Be '-p, --path <PATH>'
    }
}

Describe 'Get-NovaCliHelpOptionLabelWidth' {
    It 'returns 0 for empty options' {
        Get-NovaCliHelpOptionLabelWidth -Options @() | Should -Be 0
    }
    It 'returns max width across options' {
        $opts = @(
            (New-TestOption -Short '-h' -Long '--help')
            (New-TestOption -Short '-p' -Long '--path' -Placeholder '<PATH>')
        )
        Get-NovaCliHelpOptionLabelWidth -Options $opts | Should -Be 17
    }
}

Describe 'Format-NovaCliShortOptionLine' {
    It 'pads label to LabelWidth and appends description' {
        $opt = New-TestOption -Short '-h' -Long '--help' -Description 'show help'
        $line = Format-NovaCliShortOptionLine -Option $opt -LabelWidth 20
        $line | Should -Be '  -h, --help            show help'
    }
}

Describe 'Format-NovaCliLongOptionBlock' {
    It 'returns label and indented description' {
        $opt = New-TestOption -Short '-h' -Long '--help' -Description 'show help'
        $block = Format-NovaCliLongOptionBlock -Option $opt
        $block.Count | Should -Be 2
        $block[0] | Should -Be '  -h, --help'
        $block[1] | Should -Be '      show help'
    }
}

Describe 'Get-NovaCliShortOptionText' {
    It 'returns (none) for empty list' {
        Get-NovaCliShortOptionText -Options @() | Should -Be '  (none)'
    }
    It 'formats each option as a padded line' {
        $opts = @((New-TestOption -Short '-h' -Long '--help' -Description 'help'))
        $text = @(Get-NovaCliShortOptionText -Options $opts)
        $text[-1] | Should -Match '-h, --help.*help'
    }
}

Describe 'Get-NovaCliLongOptionText' {
    It 'returns (none) for empty list' {
        Get-NovaCliLongOptionText -Options @() | Should -Be '  (none)'
    }
    It 'separates options with a blank line and ends without trailing blank' {
        $opts = @(
            (New-TestOption -Short '-h' -Long '--help' -Description 'h')
            (New-TestOption -Short '-v' -Long '--verbose' -Description 'v')
        )
        $lines = Get-NovaCliLongOptionText -Options $opts
        $lines.Count | Should -Be 5
        $lines[2] | Should -Be ''
        $lines[-1] | Should -Be '      v'
    }
}

Describe 'Get-NovaCliExampleText' {
    It 'returns (none) for empty list' {
        Get-NovaCliExampleText -Examples @() | Should -Be '  (none)'
    }
    It 'renders each example with command and description, separated by blanks' {
        $examples = @(
            [pscustomobject]@{Command='nova build'; Description='build'}
            [pscustomobject]@{Command='nova test'; Description='test'}
        )
        $lines = Get-NovaCliExampleText -Examples $examples
        $lines.Count | Should -Be 5
        $lines[0] | Should -Be '  nova build'
        $lines[1] | Should -Be '      build'
        $lines[2] | Should -Be ''
    }
}

Describe 'Format-NovaCliShortCommandHelp' {
    It 'renders usage, summary, and options sections' {
        $def = @{
            Usage='nova build [options]'
            Summary='Builds the module.'
            Options=@((New-TestOption -Short '-h' -Long '--help' -Description 'help'))
        }
        $out = Format-NovaCliShortCommandHelp -Definition $def
        $out | Should -Match 'usage: nova build'
        $out | Should -Match 'Builds the module\.'
        $out | Should -Match 'Options:'
    }
}

Describe 'Format-NovaCliLongCommandHelp' {
    It 'renders NAME, SYNOPSIS, DESCRIPTION, OPTIONS, EXAMPLES sections' {
        $def = @{
            Command='build'
            Summary='Builds'
            Usage='nova build [options]'
            Description=@('First desc line','Second desc line')
            Options=@((New-TestOption -Short '-h' -Long '--help' -Description 'help'))
            Examples=@([pscustomobject]@{Command='nova build'; Description='example'})
        }
        $out = Format-NovaCliLongCommandHelp -Definition $def
        $out | Should -Match 'NAME'
        $out | Should -Match 'nova build - Builds'
        $out | Should -Match 'SYNOPSIS'
        $out | Should -Match 'DESCRIPTION'
        $out | Should -Match 'First desc line'
        $out | Should -Match 'OPTIONS'
        $out | Should -Match 'EXAMPLES'
    }
}

Describe 'Format-NovaCliCommandHelp' {
    It 'defaults to Short view' {
        $def = @{
            Usage='nova info'; Summary='Info'
            Options=@()
        }
        Format-NovaCliCommandHelp -Definition $def | Should -Match 'usage: nova info'
    }
    It 'renders Long view when requested' {
        $def = @{
            Command='info'; Summary='Info'; Usage='nova info'
            Description=@('desc'); Options=@(); Examples=@()
        }
        Format-NovaCliCommandHelp -Definition $def -View Long | Should -Match '^NAME'
    }
}
