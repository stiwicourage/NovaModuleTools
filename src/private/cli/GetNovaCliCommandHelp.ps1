function Test-NovaCliHelpToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Argument
    )

    return $Argument -match '^(--help|-h)$'
}

function Get-NovaCliCommandHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [ValidateSet('Short', 'Long')][string]$View = 'Short'
    )

    $definition = Get-NovaCliCommandHelpDefinition -Command $Command
    return Format-NovaCliCommandHelp -Definition $definition -View $View
}

