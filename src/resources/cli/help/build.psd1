@{
    Command = 'build'
    Summary = 'Build the module into the dist folder.'
    Usage = 'nova build [<options>]'
    Description = @(
        'Build the current project into the dist folder.',
        'Use this command when you want fresh built module output before testing, packaging, or publishing.'
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
            Description = 'Preview the build workflow without changing files.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the build workflow runs.'
        }
    )
    Examples = @(
        @{
            Command = 'nova build'
            Description = 'Build the current project.'
        },
        @{
            Command = 'nova build --what-if'
            Description = 'Preview the build workflow without writing output.'
        }
    )
}

