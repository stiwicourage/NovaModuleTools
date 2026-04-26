@{
    Command = 'info'
    Summary = 'Show project information.'
    Usage = 'nova info'
    Description = @(
        'Show project information for the current Nova module project.',
        'Use this command when you want the resolved project metadata without changing files.'
    )
    Options = @()
    Examples = @(
        @{
            Command = 'nova info'
            Description = 'Show project information for the current project.'
        }
    )
}

