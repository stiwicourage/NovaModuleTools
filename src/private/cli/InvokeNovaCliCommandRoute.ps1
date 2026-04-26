function Get-NovaCliCommandHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$CommandHandlerMap,
        [Parameter(Mandatory)][string]$Command
    )

    $commandHandler = $CommandHandlerMap[$Command]
    if ($null -eq $commandHandler) {
        Stop-NovaOperation -Message "Unknown command: <$Command> | Use 'nova --help' to see available commands." -ErrorId 'Nova.Validation.UnknownCliCommand' -Category InvalidArgument -TargetObject $Command
    }

    return $commandHandler
}

function Confirm-NovaCliRoutedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext,
        [Parameter(Mandatory)][string]$Command
    )

    if (-not $InvocationContext.CliConfirmEnabled) {
        return
    }

    if ($InvocationContext.WhatIfEnabled) {
        return
    }

    if (-not (Test-NovaCliMutatingCommand -Command $Command)) {
        return
    }

    Confirm-NovaCliCommandAction -Command $Command
}

function Invoke-NovaCliCommandRoute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    if ($InvocationContext.IsHelpRequest) {
        if ($InvocationContext.HelpRequest.TargetType -eq 'Root') {
            return Get-NovaCliHelp
        }

        return Get-NovaCliCommandHelp -Command $InvocationContext.HelpRequest.Command -View $InvocationContext.HelpRequest.View
    }

    $command = $InvocationContext.Command
    $arguments = $InvocationContext.Arguments
    $commonParameters = $InvocationContext.CommonParameters
    $mutatingCommonParameters = $InvocationContext.MutatingCommonParameters

    $commandHandlerMap = @{
        'info' = {
            Get-NovaProjectInfo @commonParameters
        }
        'version' = {
            Invoke-NovaCliVersionCommand -Arguments $arguments -ForwardedParameters $commonParameters
        }
        'build' = {
            Invoke-NovaBuild @mutatingCommonParameters
        }
        'test' = {
            $options = ConvertFrom-NovaTestCliArgument -Arguments $arguments
            Test-NovaBuild @options @mutatingCommonParameters
        }
        'package' = {
            New-NovaModulePackage @mutatingCommonParameters
        }
        'deploy' = {
            Invoke-NovaCliDeployCommand -Arguments $arguments -ForwardedParameters $mutatingCommonParameters
        }
        'init' = {
            Invoke-NovaCliInitCommand -Arguments $arguments -ForwardedParameters $mutatingCommonParameters -WhatIfEnabled:$InvocationContext.WhatIfEnabled
        }
        'bump' = {
            $options = ConvertFrom-NovaBumpCliArgument -Arguments $arguments
            Update-NovaModuleVersion @options @mutatingCommonParameters
        }
        'update' = {
            $result = Invoke-NovaCliUpdateCommand -Arguments $arguments -ForwardedParameters $mutatingCommonParameters
            Format-NovaCliCommandResult -Command $command -Result $result
        }
        'publish' = {
            $options = ConvertFrom-NovaCliArgument -Arguments $arguments
            Publish-NovaModule @options @mutatingCommonParameters
        }
        'release' = {
            $options = ConvertFrom-NovaCliArgument -Arguments $arguments
            Invoke-NovaRelease -PublishOption $options @mutatingCommonParameters
        }
        'notification' = {
            Invoke-NovaCliNotificationCommand -Arguments $arguments -CommonParameters $commonParameters -MutatingCommonParameters $mutatingCommonParameters
        }
        '--version' = {
            $moduleVersion = Get-NovaCliInstalledVersion
            Format-NovaCliVersionString -Name $InvocationContext.ModuleName -Version $moduleVersion
        }
        '--help' = {
            Get-NovaCliHelp
        }
    }

    $commandHandler = Get-NovaCliCommandHandler -CommandHandlerMap $commandHandlerMap -Command $command
    Confirm-NovaCliRoutedCommand -InvocationContext $InvocationContext -Command $command

    return & $commandHandler
}
