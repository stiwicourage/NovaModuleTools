@{
    Command = 'publish'
    Summary = 'Build, test, and publish the module locally or to a repository.'
    Usage = 'nova publish [<options>]'
    Description = @(
        'Build, test, and publish the current project either locally or to a PowerShell repository.',
        'Use --skip-tests / -s when tests already ran earlier in CI/CD and you only want to skip Test-NovaBuild for this publish run.',
        'Use --local when you want a local publish workflow, or supply repository credentials when you want a repository publish.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/packaging-and-delivery.html#publish'
    )
    Options = @(
        @{
            Short = '-l'
            Long = '--local'
            Placeholder = ''
            Description = 'Publish to the resolved local module path instead of a repository.'
        },
        @{
            Short = '-r'
            Long = '--repository'
            Placeholder = '<name>'
            Description = 'Publish to the specified PowerShell repository.'
        },
        @{
            Short = '-p'
            Long = '--path'
            Placeholder = '<path>'
            Description = 'Use the specified local publish directory path.'
        },
        @{
            Short = '-k'
            Long = '--api-key'
            Placeholder = '<key>'
            Description = 'Use the specified API key for repository publishing.'
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
            Description = 'Preview the publish workflow without publishing the module.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the publish workflow runs.'
        },
        @{
            Short = '-s'
            Long = '--skip-tests'
            Placeholder = ''
            Description = 'Skip Test-NovaBuild for this publish run. Build still runs, which is useful when tests already passed earlier in CI/CD.'
        },
        @{
            Short = '-i'
            Long = '--continuous-integration'
            Placeholder = ''
            Description = 'Re-import the built dist module after publish finishes so later CI steps in the same session keep using the built module state.'
        }
    )
    Examples = @(
        @{
            Command = 'nova publish --local'
            Description = 'Build, test, and publish the module to the local module path.'
        },
        @{
            Command = 'nova publish --repository PSGallery --api-key <key>'
            Description = 'Build, test, and publish the module to a PowerShell repository.'
        },
        @{
            Command = 'nova publish --repository PSGallery --api-key <key> --skip-tests'
            Description = 'Build and publish the module without re-running Test-NovaBuild.'
        },
        @{
            Command = 'nova publish --repository PSGallery --api-key <key> --continuous-integration'
            Description = 'Publish the module and then restore the built dist module state for later CI steps in the same session.'
        }
    )
}
