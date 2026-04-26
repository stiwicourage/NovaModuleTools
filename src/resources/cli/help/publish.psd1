@{
    Command = 'publish'
    Summary = 'Build, test, and publish the module locally or to a repository.'
    Usage = 'nova publish [<options>]'
    Description = @(
        'Build, test, and publish the current project either locally or to a PowerShell repository.',
        'Use --local when you want a local publish workflow, or supply repository credentials when you want a repository publish.'
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
        }
    )
}

