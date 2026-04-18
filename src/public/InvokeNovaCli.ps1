function Invoke-NovaCli {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('nova')]
    param(
        [Parameter(Position = 0)]
        [string]$Command = '--help',

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $commonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $PSBoundParameters
    $mutatingCommonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $PSBoundParameters -IncludeShouldProcess

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments

    switch ($Command) {
        'info' {
            return Get-NovaProjectInfo @commonParameters
        }
        'version' {
            $projectInfo = Get-NovaProjectInfo @commonParameters
            return Format-NovaCliVersionString -Name $projectInfo.ProjectName -Version $projectInfo.Version
        }
        'build' {
            return Invoke-NovaBuild @mutatingCommonParameters
        }
        'test' {
            return Test-NovaBuild @mutatingCommonParameters
        }
        'init' {
            if ($WhatIfPreference) {
                throw "The 'nova init' CLI command does not support -WhatIf. Run 'nova init' or 'nova init -Path <path>' without -WhatIf."
            }

            $options = ConvertFrom-NovaInitCliArgument -Arguments $Arguments
            return New-NovaModule @options @mutatingCommonParameters
        }
        'bump' {
            return Update-NovaModuleVersion @mutatingCommonParameters
        }
        'publish' {
            $options = ConvertFrom-NovaCliArgument -Arguments $Arguments
            return Publish-NovaModule @options @mutatingCommonParameters
        }
        'release' {
            $options = ConvertFrom-NovaCliArgument -Arguments $Arguments
            return Invoke-NovaRelease -PublishOption $options @mutatingCommonParameters
        }
        'notification' {
            $notificationAction = ConvertFrom-NovaNotificationCliArgument -Arguments $Arguments
            if ($notificationAction -eq 'status') {
                return Get-NovaUpdateNotificationPreference @commonParameters
            }

            if ($notificationAction -eq 'enable') {
                return Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications @mutatingCommonParameters
            }

            return Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications @mutatingCommonParameters
        }
        '--version' {
            $moduleName = $ExecutionContext.SessionState.Module.Name
            $moduleVersion = Get-NovaCliInstalledVersion
            return Format-NovaCliVersionString -Name $moduleName -Version $moduleVersion
        }
        '--help' {
            return Get-NovaCliHelp
        }
        default {
            throw "Unknown command: <$Command> | Use 'nova --help' to see available commands."
        }
    }
}



