BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/WriteNovaModuleReleaseNotesLink.ps1')

    function Get-NovaModuleReleaseNotesUri {param([object]$Module)}
}

Describe 'Get-NovaModuleReleaseNotesMessage' {
    It 'returns a release notes message when a URI is configured' {
        Mock Get-NovaModuleReleaseNotesUri {return 'https://example/notes'}

        Get-NovaModuleReleaseNotesMessage -Module ([pscustomobject]@{}) | Should -Be 'Release notes: https://example/notes'
    }

    It 'returns null when no URI is configured' {
        Mock Get-NovaModuleReleaseNotesUri {return $null}

        Get-NovaModuleReleaseNotesMessage -Module ([pscustomobject]@{}) | Should -BeNullOrEmpty
    }

    It 'uses an explicit URI when called via the Uri parameter set' {
        Get-NovaModuleReleaseNotesMessage -ReleaseNotesUri 'https://example/n' | Should -Be 'Release notes: https://example/n'
    }
}

Describe 'Write-NovaModuleReleaseNotesLink' {
    It 'writes the formatted message to host when a URI is configured' {
        Mock Get-NovaModuleReleaseNotesUri {return 'https://example/notes'}
        Mock Write-Host {}

        Write-NovaModuleReleaseNotesLink -Module ([pscustomobject]@{})

        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $args -contains 'Release notes: https://example/notes' -or $Object -eq 'Release notes: https://example/notes'
        }
    }

    It 'is a no-op when no URI is configured' {
        Mock Get-NovaModuleReleaseNotesUri {return $null}
        Mock Write-Host {}

        Write-NovaModuleReleaseNotesLink -Module ([pscustomobject]@{})

        Should -Invoke Write-Host -Times 0
    }
}
