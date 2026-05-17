BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertFromNovaCliSwitchArgument.ps1')

    . (Join-Path $PSScriptRoot 'ConvertFromNovaCliSwitchArgument.TestSupport.ps1')
}

Describe 'Get-NovaCliSwitchOptionName' {
    It 'returns the mapped option name' {
        Get-NovaCliSwitchOptionName -TokenMap @{'-x' = 'Foo'} -Token '-x' | Should -Be 'Foo'
    }

    It 'throws for unknown tokens' {
        {Get-NovaCliSwitchOptionName -TokenMap @{} -Token '-y'} | Should -Throw '*Unknown argument: -y*'
    }
}

Describe 'ConvertFrom-NovaCliSwitchArgument' {
    It 'sets each token-mapped option to $true' {
        $tokenMap = @{'-a' = 'AOpt'; '-b' = 'BOpt'}
        $options = ConvertFrom-NovaCliSwitchArgument -Arguments @('-a', '-b') -TokenMap $tokenMap
        $options.AOpt | Should -BeTrue
        $options.BOpt | Should -BeTrue
    }

    It 'throws when an argument is not in the token map' {
        {ConvertFrom-NovaCliSwitchArgument -Arguments @('-z') -TokenMap @{}} | Should -Throw '*Unknown argument*'
    }
}
