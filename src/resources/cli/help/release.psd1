@{
    Command = 'release'
    Summary = 'Run the full release flow.'
    Usage = 'nova release [<options>]'
    Description = @(
        'Run the full release flow: build, test, version bump, rebuild, and publish.',
        'Use the same publish-target options as nova publish when you want the release workflow to publish locally or to a repository.'
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
        }
    )
}

