BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaTest integration' {
    It 'supports WhatIf from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            Invoke-NovaTest -WhatIf
        }

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
    }

    It 'fails early when the isolated session cannot resolve a supported Pester 5.x module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            $temporaryModulePath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().Guid)
            $originalModulePath = $env:PSModulePath
            try {
                New-NovaPublicCommandIntegrationPesterModule -BasePath $temporaryModulePath -Version '6.0.0' | Out-Null
                $env:PSModulePath = $temporaryModulePath
                Invoke-NovaTest -WhatIf
            } finally {
                $env:PSModulePath = $originalModulePath
                Remove-Item -LiteralPath $temporaryModulePath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        $outputText = $result.Output -join [Environment]::NewLine
        $result.ExitCode | Should -Not -Be 0
        $outputText | Should -Match 'Pester'
        $outputText | Should -Match 'Import-Module'
        $outputText | Should -Match 'was not loaded because no valid module file was found|5\.7\.1 through 5\.10\.0'
    }

    It 'supports a guarded Run.Container override from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            $container = New-PesterContainer -Path 'tests/public/InvokeNovaTest.Tests.ps1' -Data @{Name = 'runtime-value'}
            Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                Run = @{
                    Container = @($container)
                }
            }
        }

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
    }

    It 'rejects non-file Run.Container overrides from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            $container = [pscustomobject]@{
                Type = 'ScriptBlock'
                Item = $null
                Data = @{}
            }
            Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                Run = @{
                    Container = @($container)
                }
            }
        }

        $result.ExitCode | Should -Not -Be 0
        ($result.Output -join [Environment]::NewLine) | Should -Match 'ScriptBlock and other container types are not supported'
    }

    It 'rejects unsupported override shapes from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                Run = @{
                    Path = @('tests/public/InvokeNovaTest.Tests.ps1')
                }
            }
        }

        $result.ExitCode | Should -Not -Be 0
        ($result.Output -join [Environment]::NewLine) | Should -Match 'Unsupported override path: Run.Path'
    }
}
