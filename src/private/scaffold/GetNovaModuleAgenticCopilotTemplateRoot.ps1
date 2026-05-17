function Get-NovaModuleAgenticCopilotTemplateRoot {
    [CmdletBinding()]
    param()

    $sentinelPath = Get-ResourceFilePath -FileName ([System.IO.Path]::Combine('agentic-copilot', 'AGENTS.md'))
    return Split-Path -Parent $sentinelPath
}
