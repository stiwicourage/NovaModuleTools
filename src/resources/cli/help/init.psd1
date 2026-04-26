@{
    Command = 'init'
    Summary = 'Create a new Nova module scaffold.'
    Usage = 'nova init [<options>]'
    Description = @(
        'Create a new Nova module scaffold.',
        'Run without options for the interactive flow, or pass an explicit destination path when you want a non-interactive target.'
    )
    Options = @(
        @{
            Short = '-p'
            Long = '--path'
            Placeholder = '<path>'
            Description = 'Write the scaffold to the specified destination path.'
        },
        @{
            Short = '-e'
            Long = '--example'
            Placeholder = ''
            Description = 'Use the packaged example scaffold instead of the standard starter.'
        }
    )
    Examples = @(
        @{
            Command = 'nova init'
            Description = 'Start the interactive scaffold flow.'
        },
        @{
            Command = 'nova init --path ~/Work'
            Description = 'Create a new module scaffold at an explicit destination.'
        },
        @{
            Command = 'nova init --example --path ~/Work'
            Description = 'Create the packaged example scaffold at an explicit destination.'
        }
    )
}

