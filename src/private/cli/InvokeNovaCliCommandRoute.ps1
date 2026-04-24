function Invoke-NovaCliCommandRoute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    if ($InvocationContext.IsHelpRequest) {
        return Get-NovaCliCommandHelp -Command $InvocationContext.Command
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
            Test-NovaBuild @mutatingCommonParameters
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

    $commandHandler = $commandHandlerMap[$command]
    if ($null -eq $commandHandler) {
        throw "Unknown command: <$command> | Use 'nova --help' to see available commands."
    }

    return & $commandHandler
}
