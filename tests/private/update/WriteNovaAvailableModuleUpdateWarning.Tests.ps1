BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/WriteNovaAvailableModuleUpdateWarning.ps1')
    function Get-NovaModuleReleaseNotesUri {return $null}
}

Describe 'Write-NovaAvailableModuleUpdateWarning' {
    It 'warns about a stable release with versions and update command' {
        Mock Get-NovaModuleReleaseNotesUri { $null }
        Mock Write-Warning {}
        Write-NovaAvailableModuleUpdateWarning -CurrentVersion '1.0.0' -AvailableVersion '1.1.0'
        Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {
            $Message -match 'newer NovaModuleTools release' -and
            $Message -match 'Current: 1\.0\.0' -and
            $Message -match 'Available: 1\.1\.0' -and
            $Message -match 'Update-Module NovaModuleTools' -and
            $Message -notmatch 'AllowPrerelease' -and
            $Message -notmatch 'prerelease'
        }
    }

    It 'warns about a prerelease with AllowPrerelease and notification opt-out' {
        Mock Get-NovaModuleReleaseNotesUri { $null }
        Mock Write-Warning {}
        Write-NovaAvailableModuleUpdateWarning -CurrentVersion '1.0.0' -AvailableVersion '1.1.0-beta1' -Prerelease
        Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {
            $Message -match 'newer NovaModuleTools prerelease' -and
            $Message -match '-AllowPrerelease' -and
            $Message -match 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
        }
    }

    It 'includes release notes link when available' {
        Mock Get-NovaModuleReleaseNotesUri { 'https://example.com/notes' }
        Mock Write-Warning {}
        Write-NovaAvailableModuleUpdateWarning -CurrentVersion '1.0.0' -AvailableVersion '1.1.0'
        Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {
            $Message -match 'Release notes: https://example\.com/notes'
        }
    }
}
