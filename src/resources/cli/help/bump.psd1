@{
    Command = 'bump'
    Summary = 'Update the module version in project.json.'
    Usage = 'nova bump [<options>]'
    Description = @(
        'Update the module version in project.json by using the current repository history.',
        'Use --preview when you want an explicit prerelease iteration instead of the next stable semantic version.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/versioning-and-updates.html#bump'
    )
    Options = @(
        @{
            Short = '-p'
            Long = '--preview'
            Placeholder = ''
            Description = 'Keep the next version in prerelease form instead of finalizing a stable target.'
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
            Description = 'Preview the next version without changing project.json.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the version update runs.'
        }
    )
    Examples = @(
        @{
            Command = 'nova bump'
            Description = 'Calculate and apply the next semantic version for the current project.'
        },
        @{
            Command = 'nova bump --preview --what-if'
            Description = 'Preview the next prerelease version without updating project.json.'
        }
    )
}

