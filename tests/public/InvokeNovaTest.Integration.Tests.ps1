. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaTest integration' {
    It 'supports WhatIf from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            Invoke-NovaTest -WhatIf
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -BeNullOrEmpty
    }

    It 'supports a guarded Run.Container override from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            $container = New-PesterContainer -Path 'tests/public/InvokeNovaTest.Tests.ps1' -Data @{Name = 'runtime-value'}
            Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                Run = @{
                    Container = @($container)
                }
            }
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -BeNullOrEmpty
    }

    It 'rejects non-file Run.Container overrides from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            $container = New-PesterContainer -ScriptBlock {}
            Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                Run = @{
                    Container = @($container)
                }
            }
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.Exception.Message | Should -BeLike '*ScriptBlock and other container types are not supported*'
    }

    It 'rejects unsupported override shapes from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            Invoke-NovaTest -WhatIf -PesterConfigurationOverride @{
                Run = @{
                    Path = @('tests/public/InvokeNovaTest.Tests.ps1')
                }
            }
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.Exception.Message | Should -BeLike '*Unsupported override path: Run.Path*'
    }
}
