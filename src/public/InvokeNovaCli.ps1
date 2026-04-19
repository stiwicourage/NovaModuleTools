function Invoke-NovaCli {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('nova')]
    param(
        [Parameter(Position = 0)]
        [string]$Command = '--help',
        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $commonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $PSBoundParameters; $mutatingCommonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $PSBoundParameters -IncludeShouldProcess

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments

    switch ($Command) {
        'info' {
            return Get-NovaProjectInfo @commonParameters
        }
        'version' {
            return Invoke-NovaCliVersionCommand -Arguments $Arguments -ForwardedParameters $commonParameters
        }
        'build' {
            return Invoke-NovaBuild @mutatingCommonParameters
        }
        'test' {
            return Test-NovaBuild @mutatingCommonParameters
        }
        'pack' {
            return Pack-NovaModule @mutatingCommonParameters
        }
        'upload' {
            return Invoke-NovaCliUploadCommand -Arguments $Arguments -ForwardedParameters $mutatingCommonParameters
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
        'update' {
            $result = Invoke-NovaCliUpdateCommand -Arguments $Arguments -ForwardedParameters $mutatingCommonParameters
            return Format-NovaCliCommandResult -Command $Command -Result $result
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
            return Invoke-NovaCliNotificationCommand -Arguments $Arguments -CommonParameters $commonParameters -MutatingCommonParameters $mutatingCommonParameters
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
