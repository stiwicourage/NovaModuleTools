BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleSelfUpdate.ps1')

    function Get-NovaModuleUpdateParameterMap {
        param([string]$ModuleName, [bool]$AllowPrereleaseRequested)
        $map = @{Name = $ModuleName; ErrorAction = 'Stop'}
        if ($AllowPrereleaseRequested) {$map.AllowPrerelease = $true}
        return $map
    }

    function Invoke-NovaModuleUpdateCommand {
        param([hashtable]$UpdateParameters)
        return [pscustomobject]@{Updated = $true; Parameters = $UpdateParameters}
    }
}

Describe 'Invoke-NovaModuleSelfUpdate' {
    It 'uses the parameter map produced by Get-NovaModuleUpdateParameterMap' {
        Mock Get-NovaModuleUpdateParameterMap {return @{Name = $ModuleName; ErrorAction = 'Stop'; AllowPrerelease = $AllowPrereleaseRequested}}
        Mock Invoke-NovaModuleUpdateCommand {return [pscustomobject]@{Parameters = $UpdateParameters}}

        $result = Invoke-NovaModuleSelfUpdate -ModuleName 'NovaModuleTools' -AllowPrerelease

        Should -Invoke Get-NovaModuleUpdateParameterMap -Times 1 -ParameterFilter {
            $ModuleName -eq 'NovaModuleTools' -and $AllowPrereleaseRequested -eq $true
        }
        Should -Invoke Invoke-NovaModuleUpdateCommand -Times 1
        $result.Parameters.AllowPrerelease | Should -BeTrue
    }

    It 'defaults the module name to NovaModuleTools and omits AllowPrerelease when not requested' {
        Mock Get-NovaModuleUpdateParameterMap {return @{Name = $ModuleName; ErrorAction = 'Stop'}}
        Mock Invoke-NovaModuleUpdateCommand {return $null}

        Invoke-NovaModuleSelfUpdate | Out-Null

        Should -Invoke Get-NovaModuleUpdateParameterMap -Times 1 -ParameterFilter {
            $ModuleName -eq 'NovaModuleTools' -and $AllowPrereleaseRequested -eq $false
        }
    }
}
