@{
    Command = 'test'
    Summary = 'Run Pester tests for the project.'
    Usage = 'nova test [<options>]'
    Description = @(
        'Run Pester tests for the current project.',
        'Use this command when you want Nova to run the configured project test workflow and write the normal test artifacts.'
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
            Description = 'Preview the test workflow without running Pester or writing artifacts.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the test workflow runs.'
        }
    )
    Examples = @(
        @{
            Command = 'nova test'
            Description = 'Run the project test workflow.'
        },
        @{
            Command = 'nova test -w'
            Description = 'Preview the test workflow without running tests.'
        }
    )
}

