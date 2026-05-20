@{
    Command = 'copilot'
    Summary = 'Apply or refresh the Nova Agentic Copilot scaffold in the current project.'
    Usage = 'nova copilot [<options>]'
    Description = @(
        'Apply or refresh Nova''s managed Agentic Copilot scaffold in an existing project root.',
        'This command refreshes Nova-managed guidance paths and creates README.md, CHANGELOG.md, and RELEASE_NOTE.md only when they are missing.',
        'Use --short-name to provide the placeholder short name used in generated guidance such as Invoke-<ShortName>*.',
        'By default Nova prompts before overwriting the managed scaffold paths. Use --override-warning only when you intentionally want a non-interactive apply.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/core-workflows.html#agentic-copilot'
    )
    Options = @(
        @{
            Short = '-p'
            Long = '--path'
            Placeholder = '<path>'
            Description = 'Use a specific project root instead of the current location.'
        },
        @{
            Short = '-n'
            Long = '--short-name'
            Placeholder = '<name>'
            Description = 'Provide the short placeholder name used in generated guidance content.'
        },
        @{
            Short = '-o'
            Long = '--override-warning'
            Placeholder = ''
            Description = 'Skip the overwrite warning prompt and apply the managed scaffold directly.'
        },
        @{
            Short = '-v'
            Long = '--verbose'
            Placeholder = ''
            Description = 'Show verbose output for this command.'
        },
        @{
            Short = '-w'
            Long = '--what-if'
            Placeholder = ''
            Description = 'Preview the scaffold apply workflow without changing files.'
        }
    )
    Examples = @(
        @{
            Command = 'nova copilot --short-name NMT'
            Description = 'Apply or refresh the Agentic Copilot scaffold in the current project.'
        },
        @{
            Command = 'nova copilot --path ~/Work/MyModule --short-name NMT --override-warning'
            Description = 'Apply the managed scaffold non-interactively in a specific project root.'
        },
        @{
            Command = 'nova copilot -n NMT -o'
            Description = 'Apply the managed scaffold non-interactively in the current project by using the short override flag.'
        }
    )
}
