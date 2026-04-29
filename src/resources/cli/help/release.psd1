@{
    Command = 'release'
    Summary = 'Run the full release flow.'
    Usage = 'nova release [<options>]'
    Description = @(
        'Run the full release flow: build, test, version bump, rebuild, and publish.',
        'Use --skip-tests / -s when tests already ran earlier in CI/CD and you only want to skip the pre-release Test-NovaBuild step.',
        'Use the same publish-target options as nova publish when you want the release workflow to publish locally or to a repository.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/packaging-and-delivery.html#release'
    )
    Options = @(
        @{
            Short = '-l'
            Long = '--local'
            Placeholder = ''
            Description = 'Publish the release output to the resolved local module path.'
        },
        @{
            Short = '-r'
            Long = '--repository'
            Placeholder = '<name>'
            Description = 'Publish the release output to the specified PowerShell repository.'
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
            Description = 'Preview the release workflow without changing files or publishing output.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the release workflow runs.'
        },
        @{
            Short = '-s'
            Long = '--skip-tests'
            Placeholder = ''
            Description = 'Skip the pre-release Test-NovaBuild step. Both build steps still run, which is useful when tests already passed earlier in CI/CD.'
        },
        @{
            Short = '-i'
            Long = '--continuous-integration'
            Placeholder = ''
            Description = 'Re-activate the built dist module at the release workflow boundaries where session state matters so later CI steps keep using the fresh build output.'
        }
    )
    Examples = @(
        @{
            Command = 'nova release --repository PSGallery --api-key <key>'
            Description = 'Run the full release workflow and publish to a repository.'
        },
        @{
            Command = 'nova release --local --what-if'
            Description = 'Preview the full release workflow for a local publish target.'
        },
        @{
            Command = 'nova release --repository PSGallery --api-key <key> --skip-tests'
            Description = 'Run the release workflow without re-running the pre-release Test-NovaBuild step.'
        },
        @{
            Command = 'nova release --local --continuous-integration --what-if'
            Description = 'Preview the release workflow and CI-safe reactivation flow without changing files or publishing output.'
        }
    )
}
