@{
    Command = 'build'
    Summary = 'Build the module into the dist folder.'
    Usage = 'nova build [<options>]'
    Description = @(
        'Build the current project into the dist folder.',
        'Use this command when you want fresh built module output before testing, packaging, or publishing.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/core-workflows.html#build'
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
        },
        @{
            Short = '-i'
            Long = '--continuous-integration'
            Placeholder = ''
            Description = 'Re-import the freshly built dist module before returning so later CI steps in the same session use the updated build output.'
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
        },
        @{
            Command = 'nova build --continuous-integration'
            Description = 'Build the project and re-activate the freshly built dist module for later CI steps in the same session.'
        }
    )
}
