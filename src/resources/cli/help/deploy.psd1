@{
    Command = 'deploy'
    Summary = 'Upload generated package artifact(s) to a raw HTTP endpoint.'
    Usage = 'nova deploy [<options>]'
    Description = @(
        'Upload existing package artifact(s) from the current project to a raw HTTP endpoint.',
        'Use a named repository from project.json or pass an explicit URL when you want a direct upload target.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/packaging-and-delivery.html#upload'
    )
    Options = @(
        @{
            Short = '-r'
            Long = '--repository'
            Placeholder = '<name>'
            Description = 'Resolve the upload target from a named package repository in project.json.'
        },
        @{
            Short = '-u'
            Long = '--url'
            Placeholder = '<url>'
            Description = 'Upload to the specified raw HTTP endpoint instead of a named repository.'
        },
        @{
            Short = '-p'
            Long = '--path'
            Placeholder = '<path>'
            Description = 'Upload the specified package file path instead of discovering package output automatically.'
        },
        @{
            Short = '-t'
            Long = '--type'
            Placeholder = '<type>'
            Description = 'Limit uploads to the specified package type, such as NuGet or Zip.'
        },
        @{
            Short = '-o'
            Long = '--upload-path'
            Placeholder = '<path>'
            Description = 'Append an upload path segment below the resolved repository or URL target.'
        },
        @{
            Short = '-k'
            Long = '--token'
            Placeholder = '<token>'
            Description = 'Use the specified authentication token for the upload request.'
        },
        @{
            Short = '-e'
            Long = '--token-env'
            Placeholder = '<name>'
            Description = 'Read the authentication token from the specified environment variable.'
        },
        @{
            Short = '-a'
            Long = '--auth-scheme'
            Placeholder = '<scheme>'
            Description = 'Prefix the token with the specified authentication scheme, such as Bearer.'
        },
        @{
            Short = '-H'
            Long = '--header'
            Placeholder = '<name=value>'
            Description = 'Add a custom request header. Repeat the option to add multiple headers.'
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
            Description = 'Preview the upload workflow without sending any package files.'
        },
        @{
            Short = '-c'
            Long = '--confirm'
            Placeholder = ''
            Description = 'Request CLI confirmation before the upload workflow runs.'
        }
    )
    Examples = @(
        @{
            Command = 'nova deploy --repository LocalNexus'
            Description = 'Upload package artifacts by using a named repository from project.json.'
        },
        @{
            Command = 'nova deploy --url https://packages.example/raw/ --token $env:NOVA_PACKAGE_TOKEN'
            Description = 'Upload package artifacts to an explicit raw endpoint with a token.'
        }
    )
}

