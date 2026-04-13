function Invoke-NovaCli {
    [CmdletBinding()]
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
            return Invoke-NovaBuild @commonParameters
        }
        'test' {
            return Test-NovaBuild @commonParameters
        }
        'init' {
            if ($Arguments.Count -gt 0) {
                return New-NovaModule -Path $Arguments[0] @commonParameters
            }

            return New-NovaModule @commonParameters
        }
        'bump' {
            return Update-NovaModuleVersion @commonParameters
        }
        'publish' {
            $options = ConvertFrom-NovaCliArgument -Arguments $Arguments
            return Publish-NovaModule @options @commonParameters
        }
        'release' {
            $options = ConvertFrom-NovaCliArgument -Arguments $Arguments
            return Invoke-NovaRelease -PublishOption $options @commonParameters
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



