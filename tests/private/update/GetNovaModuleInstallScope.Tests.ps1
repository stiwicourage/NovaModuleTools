BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleInstallScope.ps1')
}

Describe 'Get-NovaModuleInstallScope' {
    BeforeAll {
        $script:allUsersRoot = Join-Path (Join-Path $TestDrive 'system') 'Modules'
    }

    BeforeEach {
        Mock Get-NovaAllUsersModuleRoot {$script:allUsersRoot}
    }

    It 'returns AllUsers for a module installed below the all-users module root' {
        $moduleBase = Join-Path (Join-Path $script:allUsersRoot 'NovaModuleTools') '2.0.0'

        Get-NovaModuleInstallScope -ModuleBase $moduleBase | Should -Be 'AllUsers'
    }

    It 'returns CurrentUser for a module installed outside the all-users module root' {
        $moduleBase = Join-Path (Join-Path (Join-Path $TestDrive 'user') 'NovaModuleTools') '2.0.0'

        Get-NovaModuleInstallScope -ModuleBase $moduleBase | Should -Be 'CurrentUser'
    }

    It 'does not treat a sibling directory sharing the root prefix as AllUsers' {
        $moduleBase = Join-Path "$( $script:allUsersRoot )Extra" 'NovaModuleTools'

        Get-NovaModuleInstallScope -ModuleBase $moduleBase | Should -Be 'CurrentUser'
    }
}
