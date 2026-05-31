BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaTest integration' {
    It 'supports WhatIf from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                Invoke-NovaTest -WhatIf
            }
        } | Should -Not -Throw
    }

    It 'supports a guarded Run.Container override from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                $container = New-PesterContainer -Path 'tests/public/InvokeNovaTest.Tests.ps1' -Data @{ Name = 'runtime-value' }
                Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                    Run = @{
                        Container = @($container)
                    }
                }
            }
        } | Should -Not -Throw
    }

    It 'rejects non-file Run.Container overrides from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                $container = New-PesterContainer -ScriptBlock {}
                Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                    Run = @{
                        Container = @($container)
                    }
                }
            }
        } | Should -Throw '*ScriptBlock and other container types are not supported*'
    }

    It 'rejects unsupported override shapes from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                    Run = @{
                        Path = @('tests/public/InvokeNovaTest.Tests.ps1')
                    }
                }
            }
        } | Should -Throw '*Unsupported override path: Run.Path*'
    }
}
