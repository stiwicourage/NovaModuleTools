function Invoke-NovaCli {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('nova')]
    param(
        [Parameter(Position = 0)]
        [string]$Command = '--help',

        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $commonParameters = @{}
    if ( $PSBoundParameters.ContainsKey('Verbose')) {
        $commonParameters.Verbose = $true
    }

    $mutatingCommonParameters = @{}
    foreach ($parameterKey in $commonParameters.Keys) {
        $mutatingCommonParameters[$parameterKey] = $commonParameters[$parameterKey]
    }

    if ($WhatIfPreference) {
        $mutatingCommonParameters.WhatIf = $true
    }

    if ( $PSBoundParameters.ContainsKey('Confirm')) {
        $mutatingCommonParameters.Confirm = [bool]$PSBoundParameters.Confirm
    }

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
            if ($Arguments.Count -gt 0) {
                return New-NovaModule -Path $Arguments[0] @mutatingCommonParameters
            }

            return New-NovaModule @mutatingCommonParameters
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



