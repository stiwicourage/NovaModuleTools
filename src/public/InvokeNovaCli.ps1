function Invoke-NovaCli {
    [CmdletBinding()]
    [Alias('nova')]
    param(
        [Parameter(Position = 0)]
        [ValidateSet('info', '--version', '--help', 'build', 'test', 'init', 'publish', 'bump', 'release')]
        [string]$Command = '--help',

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    switch ($Command) {
        'info' {
            return Get-NovaProjectInfo
        }
        '--version' {
            return Get-NovaProjectInfo -Version
        }
        '--help' {
            return Get-NovaCliHelp
        }
        'build' {
            return Invoke-NovaBuild
        }
        'test' {
            return Test-NovaBuild
        }
        'init' {
            if ($Arguments.Count -gt 0) {
                return New-NovaModule -Path $Arguments[0]
            }

            return New-NovaModule
        }
        'bump' {
            return Update-NovaModuleVersion
        }
        'publish' {
            $options = ConvertFrom-NovaCliArgument -Arguments $Arguments
            return Publish-NovaModule @options
        }
        'release' {
            $options = ConvertFrom-NovaCliArgument -Arguments $Arguments
            return Invoke-NovaRelease -PublishOption $options
        }
    }
}



