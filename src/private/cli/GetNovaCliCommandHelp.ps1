function Test-NovaCliHelpRequest {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return $Arguments.Count -eq 1 -and $Arguments[0] -match '^(--help|-h)$'
}

function Get-NovaCliCommandHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    $helpTarget = switch ($Command) {
        'info' {
            'Get-NovaProjectInfo'
        }
        'version' {
            'Invoke-NovaCli'
        }
        'build' {
            'Invoke-NovaBuild'
        }
        'test' {
            'Test-NovaBuild'
        }
        'package' {
            'New-NovaModulePackage'
        }
        'deploy' {
            'Deploy-NovaPackage'
        }
        'init' {
            'Initialize-NovaModule'
        }
        'bump' {
            'Update-NovaModuleVersion'
        }
        'update' {
            'Update-NovaModuleTool'
        }
        'notification' {
            'Set-NovaUpdateNotificationPreference'
        }
        'publish' {
            'Publish-NovaModule'
        }
        'release' {
            'Invoke-NovaRelease'
        }
        default {
            Stop-NovaOperation -Message "Unknown command: <$Command> | Use 'nova --help' to see available commands." -ErrorId 'Nova.Validation.UnknownCliCommand' -Category InvalidArgument -TargetObject $Command
        }
    }

    return Get-Help -Name $helpTarget -Full -ErrorAction Stop
}

