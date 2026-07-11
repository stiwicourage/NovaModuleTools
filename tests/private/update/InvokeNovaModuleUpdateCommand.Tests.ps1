BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleUpdateCommand.ps1')

    function Update-Module {
        [CmdletBinding()]
        param(
            [string]$Name,
            [switch]$AllowPrerelease,
            $ErrorAction
        )
        return [pscustomobject]@{Name = $Name; AllowPrerelease = $AllowPrerelease.IsPresent}
    }
}

Describe 'Get-NovaModuleUpdateParameterMap' {
    It 'returns a stop-on-error parameter map without AllowPrerelease by default' {
        $map = Get-NovaModuleUpdateParameterMap -ModuleName 'NovaModuleTools' -AllowPrereleaseRequested $false
        $map.Name | Should -Be 'NovaModuleTools'
        $map.ErrorAction | Should -Be 'Stop'
        $map.ContainsKey('AllowPrerelease') | Should -BeFalse
    }

    It 'includes AllowPrerelease when explicitly requested' {
        $map = Get-NovaModuleUpdateParameterMap -ModuleName 'NovaModuleTools' -AllowPrereleaseRequested $true
        $map.AllowPrerelease | Should -BeTrue
    }
}

Describe 'Invoke-NovaModuleUpdateCommand' {
    It 'delegates the parameter map to Update-Module via splatting' {
        Mock Update-Module {return [pscustomobject]@{Splatted = $true; Name = $Name; AllowPrerelease = $AllowPrerelease.IsPresent}}

        $result = Invoke-NovaModuleUpdateCommand -UpdateParameters @{Name = 'NovaModuleTools'; AllowPrerelease = $true; ErrorAction = 'Stop'}

        $result.Splatted | Should -BeTrue
        $result.Name | Should -Be 'NovaModuleTools'
        $result.AllowPrerelease | Should -BeTrue
        Should -Invoke Update-Module -Times 1
    }
}
