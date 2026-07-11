BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleUpdateLookup.ps1')

    function Get-NovaModuleUpdateLookupScript {return '# default script'}
    function Invoke-NovaPowerShellScriptWithTimeout {param([string]$Script, [object[]]$ArgumentList, [int]$TimeoutMilliseconds)}
}

Describe 'Invoke-NovaModuleUpdateLookup' {
    It 'uses the provided lookup script when one is supplied' {
        Mock Get-NovaModuleUpdateLookupScript {return '# default'}
        Mock Invoke-NovaPowerShellScriptWithTimeout {return 'forwarded'}

        $result = Invoke-NovaModuleUpdateLookup -ModuleName 'NovaModuleTools' -AllowPrereleaseNotifications $true -TimeoutMilliseconds 2000 -LookupScript '# custom'

        $result | Should -Be 'forwarded'
        Should -Invoke Get-NovaModuleUpdateLookupScript -Times 0
        Should -Invoke Invoke-NovaPowerShellScriptWithTimeout -Times 1 -ParameterFilter {
            $Script -eq '# custom' -and
            $ArgumentList.Count -eq 2 -and
            $ArgumentList[0] -eq 'NovaModuleTools' -and
            $ArgumentList[1] -eq $true -and
            $TimeoutMilliseconds -eq 2000
        }
    }

    It 'falls back to the bundled lookup script when none is provided' {
        Mock Get-NovaModuleUpdateLookupScript {return '# bundled'}
        Mock Invoke-NovaPowerShellScriptWithTimeout {return $null}

        Invoke-NovaModuleUpdateLookup -ModuleName 'NovaModuleTools' -AllowPrereleaseNotifications $false | Out-Null

        Should -Invoke Get-NovaModuleUpdateLookupScript -Times 1
        Should -Invoke Invoke-NovaPowerShellScriptWithTimeout -Times 1 -ParameterFilter {
            $Script -eq '# bundled'
        }
    }
}
