@{
    Command = 'version'
    Summary = 'Show the current project version.'
    Usage = 'nova version [<options>]'
    Description = @(
        'Show the current project version from project.json.',
        'Use --installed when you want the locally installed version of the current project module instead of the project.json version.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/versioning-and-updates.html#version-views'
    )
    Options = @(
        @{
            Short = '-i'
            Long = '--installed'
            Placeholder = ''
            Description = 'Show the locally installed version of the current project module.'
        }
    )
    Examples = @(
        @{
            Command = 'nova version'
            Description = 'Show the version from project.json.'
        },
        @{
            Command = 'nova version --installed'
            Description = 'Show the locally installed version of the current project module.'
        }
    )
}
