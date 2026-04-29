@{
    Command = 'bump'
    Summary = 'Update the module version in project.json.'
    Usage = 'nova bump [<options>]'
    Description = @(
        'Update the module version in project.json by using the current repository history.',
        'When the current stable version is 0.y.z, Nova keeps breaking-change bumps on the initial-development line and plans the next minor version instead of jumping to 1.0.0.',
        'Set 1.0.0 manually once the software is stable. After that, nova bump can increment major versions normally.',
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
        },
        @{
            Short = '-i'
            Long = '--continuous-integration'
            Placeholder = ''
            Description = 'Re-import the built dist module before the version bump workflow starts so later CI steps keep using the correct built module state.'
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
        },
        @{
            Command = 'nova bump --what-if'
            Description = 'When the current version is 0.y.z and the commit set implies a breaking change, Nova keeps the release on the 0.y.z line and prints guidance about manually promoting the project to 1.0.0 later.'
        },
        @{
            Command = 'nova bump --continuous-integration --what-if'
            Description = 'Preview the next version by using the CI-safe routed bump entrypoint without changing project.json.'
        }
    )
}
