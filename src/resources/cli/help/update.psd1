@{
    Command = 'update'
    Summary = 'Update the installed NovaModuleTools module.'
    Usage = 'nova update [<options>]'
    Description = @(
        'Update the installed NovaModuleTools module by using the stored prerelease-notification preference.',
        'Stable updates remain available by default, while prerelease targets require explicit confirmation before they run.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/versioning-and-updates.html#self-update'
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
            Description = 'Preview the self-update workflow without changing the installed module.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the self-update workflow runs.'
        }
    )
    Examples = @(
        @{
            Command = 'nova update'
            Description = 'Update the installed NovaModuleTools module.'
        },
        @{
            Command = 'nova update --what-if'
            Description = 'Preview the self-update workflow without installing anything.'
        }
    )
}
