@{
    Command = 'test'
    Summary = 'Run Pester tests for the project.'
    Usage = 'nova test [<options>]'
    Description = @(
        'Run Pester tests for the current project.',
        'Use --build when you want Nova to rebuild the project before the test workflow starts.',
        'Use this command when you want Nova to run the configured project test workflow and write the normal test artifacts.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/core-workflows.html#test'
    )
    Options = @(
        @{
            Short = '-b'
            Long = '--build'
            Placeholder = ''
            Description = 'Build the project before running the test workflow.'
        },
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
            Command = 'nova test --build'
            Description = 'Build the project first, then run the project test workflow.'
        },
        @{
            Command = 'nova test -w'
            Description = 'Preview the test workflow without running tests.'
        }
    )
}

