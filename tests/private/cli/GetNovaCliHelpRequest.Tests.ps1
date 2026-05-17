BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliHelpRequest.ps1')
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliCommandHelp.ps1')

    function Get-NovaCliNormalizedRootCommand {param([string]$Command) return $Command}
    function Get-NovaCliCommandHelpDefinition {param([string]$Command) return @{}}
    function Format-NovaCliCommandHelp {param($Definition, [string]$View) return $View}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaCliHelpUsageText' {
    It 'mentions both --help and -h forms' {
        $text = Get-NovaCliHelpUsageText
        $text | Should -Match '--help'
        $text | Should -Match '-h'
    }
}

Describe 'Get-NovaCliResolvedHelpRequest' {
    It 'builds a marked help-request object' {
        $request = Get-NovaCliResolvedHelpRequest -Command 'build' -View Short -TargetType Command
        $request.Command | Should -Be 'build'
        $request.View | Should -Be 'Short'
        $request.TargetType | Should -Be 'Command'
        $request.IsHelpRequest | Should -BeTrue
    }
}

Describe 'Assert-NovaCliHelpUsageSupported' {
    It 'always throws' {
        {Assert-NovaCliHelpUsageSupported -Tokens @('--help', 'bogus')} | Should -Throw '*Unsupported help usage*'
    }
}

Describe 'Get-NovaCliRootHelpRequest' {
    It 'returns the root short-help request for no arguments' {
        $request = Get-NovaCliRootHelpRequest -Arguments @()
        $request.Command | Should -Be '--help'
        $request.TargetType | Should -Be 'Root'
    }

    It 'returns command-targeted long help for a single command argument' {
        $request = Get-NovaCliRootHelpRequest -Arguments @('build')
        $request.Command | Should -Be 'build'
        $request.View | Should -Be 'Long'
    }

    It 'throws for unsupported argument combinations' {
        {Get-NovaCliRootHelpRequest -Arguments @('a','b')} | Should -Throw '*Unsupported help usage*'
    }
}

Describe 'Get-NovaCliSubcommandHelpRequest' {
    It 'returns $null when no arguments are present' {
        Get-NovaCliSubcommandHelpRequest -Command 'build' -Arguments @() | Should -BeNullOrEmpty
    }

    It 'returns command short help when a help token is the sole argument' {
        $request = Get-NovaCliSubcommandHelpRequest -Command 'build' -Arguments @('-h')
        $request.View | Should -Be 'Short'
        $request.TargetType | Should -Be 'Command'
    }

    It 'throws when help tokens are mixed with other arguments' {
        {Get-NovaCliSubcommandHelpRequest -Command 'build' -Arguments @('--help', '-x')} | Should -Throw '*Unsupported help usage*'
    }
}

Describe 'Get-NovaCliHelpRequest' {
    It 'routes --help command to root help' {
        Mock Get-NovaCliNormalizedRootCommand {return '--help'}
        $request = Get-NovaCliHelpRequest -Command '--help' -Arguments @()
        $request.TargetType | Should -Be 'Root'
    }

    It 'routes other commands through the subcommand path' {
        Mock Get-NovaCliNormalizedRootCommand {return 'build'}
        Get-NovaCliHelpRequest -Command 'build' -Arguments @() | Should -BeNullOrEmpty
    }
}
