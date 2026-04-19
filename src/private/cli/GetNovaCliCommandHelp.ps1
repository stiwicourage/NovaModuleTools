function Test-NovaCliHelpRequest {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return $Arguments.Count -eq 1 -and $Arguments[0] -match '^(--help|-Help)$'
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
        'merge' {
            'Merge-NovaModule'
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
            throw "Unknown command: <$Command> | Use 'nova --help' to see available commands."
        }
    }

    return Get-Help -Name $helpTarget -Full -ErrorAction Stop
}

