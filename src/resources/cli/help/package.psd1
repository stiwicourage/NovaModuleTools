@{
    Command = 'package'
    Summary = 'Build, test, and package the module as configured package artifact(s).'
    Usage = 'nova package [<options>]'
    Description = @(
        'Build, test, and package the current project by using the configured package settings.',
        'Use this command when you want package artifact output without publishing to a PowerShell repository.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/packaging-and-delivery.html#pack'
    )
    Options = @(
        @{
            Short = '-v'
            Long = '--verbose'
            Placeholder = ''
            Description = 'Show verbose output for this command. Use ''nova -v'' at the root level when you want the installed NovaModuleTools version.'
        },
        @{
            Short = '-w'
            Long = '--what-if'
            Placeholder = ''
            Description = 'Preview the package workflow without creating package artifacts.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the package workflow runs.'
        }
    )
    Examples = @(
        @{
            Command = 'nova package'
            Description = 'Build, test, and create the configured package artifacts.'
        },
        @{
            Command = 'nova package --what-if'
            Description = 'Preview the package workflow without creating artifacts.'
        }
    )
}

