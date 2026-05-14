@{
    Command = 'init'
    Summary = 'Create a new Nova module scaffold.'
    Usage = 'nova init [<options>]'
    Description = @(
        'Create a new Nova module scaffold.',
        'Run without options for the interactive flow, or pass an explicit destination path when you want a non-interactive target.',
        'When an interactive answer is invalid, Nova shows the validation message immediately and retries that prompt before moving on.',
        'Both the minimal and example scaffold flows now offer an optional Agentic Copilot starter package after the Git question. The prompt defaults to No, and the package follows Nova''s maintained agentic guidance through a filtered starter mirror.',
        'When you answer Yes, Nova also asks for a project short name used in generated guidance placeholders such as Invoke-<ShortName>*. For NovaModuleTools the short name is Nova, but it could also have been NMT.',
        'For more information, documentation, and examples, visit:',
        'https://www.novamoduletools.com/core-workflows.html#scaffold'
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
            Description = 'Start the interactive scaffold flow with immediate inline retry for invalid answers, the optional Agentic Copilot starter prompt, and the follow-up short-name prompt when Agentic setup is enabled.'
        },
        @{
            Command = 'nova init --path ~/Work'
            Description = 'Create a new module scaffold at an explicit destination.'
        },
        @{
            Command = 'nova init --example --path ~/Work'
            Description = 'Create the packaged example scaffold at an explicit destination with the same inline validation behavior, the optional Agentic Copilot starter prompt, and the follow-up short-name prompt when Agentic setup is enabled.'
        }
    )
}
