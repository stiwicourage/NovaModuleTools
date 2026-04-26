@{
    Command = 'notification'
    Summary = 'Show or change prerelease self-update eligibility.'
    Usage = 'nova notification [<options>]'
    Description = @(
        'Show or change prerelease self-update eligibility for NovaModuleTools self-updates.',
        'Run without options to show the current preference, or use --enable/--disable when you want to change it.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/versioning-and-updates.html#notification-preferences'
    )
    Options = @(
        @{
            Short = '-e'
            Long = '--enable'
            Placeholder = ''
            Description = 'Allow prerelease self-update targets again.'
        },
        @{
            Short = '-d'
            Long = '--disable'
            Placeholder = ''
            Description = 'Keep self-update on stable releases only.'
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
            Description = 'Preview enable or disable changes without updating the stored preference.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before enable or disable changes run.'
        }
    )
    Examples = @(
        @{
            Command = 'nova notification'
            Description = 'Show the current prerelease self-update preference.'
        },
        @{
            Command = 'nova notification --disable'
            Description = 'Keep self-update on stable releases only.'
        },
        @{
            Command = 'nova notification --enable'
            Description = 'Allow prerelease self-update targets again.'
        }
    )
}

