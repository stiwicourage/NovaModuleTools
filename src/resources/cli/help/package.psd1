@{
    Command = 'package'
    Summary = 'Build, test, and package the module as configured package artifact(s).'
    Usage = 'nova package [<options>]'
    Description = @(
        'Build, test, and package the current project by using the configured package settings.',
        'Use --skip-tests / -s when tests already ran earlier in CI/CD and you only want to skip Test-NovaBuild for this packaging run.',
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
        },
        @{
            Short = '-s'
            Long = '--skip-tests'
            Placeholder = ''
            Description = 'Skip Test-NovaBuild for this packaging run. Build still runs, which is useful when tests already passed earlier in CI/CD.'
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
        },
        @{
            Command = 'nova package --skip-tests'
            Description = 'Build and package the module without re-running Test-NovaBuild.'
        }
    )
}

