function Get-NovaCliHelpCommandNameList {
    [CmdletBinding()]
    param()

    return @(
        'init'
        'info'
        'version'
        'build'
        'test'
        'package'
        'deploy'
        'bump'
        'update'
        'notification'
        'publish'
        'release'
    )
}

function Get-NovaCliCommandHelpFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    return Get-ResourceFilePath -FileName "cli/help/$Command.psd1"
}

function Get-NovaCliCommandHelpDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    if ((Get-NovaCliHelpCommandNameList) -notcontains $Command) {
        Stop-NovaOperation -Message "Unknown command: <$Command> | Use 'nova --help' to see available commands." -ErrorId 'Nova.Validation.UnknownCliCommand' -Category InvalidArgument -TargetObject $Command
    }

    return Import-PowerShellDataFile -Path (Get-NovaCliCommandHelpFilePath -Command $Command)
}

