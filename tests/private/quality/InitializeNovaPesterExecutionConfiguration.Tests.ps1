BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterOutputOptionOverride.ps1')
    . (Join-Path $projectRoot 'src/private/quality/InitializeNovaPesterExecutionConfiguration.ps1')
}

function script:Stop-NovaOperation {
    param($Message, $ErrorId, $Category, $TargetObject)

    throw $Message
}

function script:New-NovaPesterExecutionConfigurationScenario {
    param(
        [string]$ProjectName = 'project',
        [string[]]$TestFileName = @('Alpha.Tests.ps1')
    )

    $projectPath = Join-Path $TestDrive $ProjectName
    $testPath = foreach ($name in $TestFileName) {
        $path = Join-Path $projectPath (Join-Path 'tests' $name)
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        Set-Content -LiteralPath $path -Value "# $name"
        $path
    }

    $config = New-PesterConfiguration
    $config.Run.Path = @($testPath)

    return [pscustomobject]@{
        ProjectPath = $projectPath
        TestPath = @($testPath)
        Config = $config
    }
}

function script:New-NovaPesterExecutionConfigurationExecutionOption {
    param(
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][object[]]$Container
    )

    return @{
        PesterConfigurationOverride = @{
            Run = @{
                Container = @($Container)
            }
        }
        ProjectRoot = $ProjectPath
    }
}

function script:Assert-NovaPesterExecutionConfigurationOverrideFailure {
    param(
        [Parameter(Mandatory)][object]$Config,
        [Parameter(Mandatory)][string]$ProjectPath,
        [Parameter(Mandatory)][object]$Override,
        [Parameter(Mandatory)][string]$ExpectedMessage
    )

    {
        Initialize-NovaPesterExecutionConfiguration -PesterConfig $Config -BoundParameters @{} -ExecutionOption @{
            PesterConfigurationOverride = $Override
            ProjectRoot = $ProjectPath
        }
    } | Should -Throw $ExpectedMessage
}

Describe 'Initialize-NovaPesterExecutionConfiguration' {
    It 'applies bound Verbosity/RenderMode and disables TestResult' {
        $config = [pscustomobject]@{
            Run = [pscustomobject]@{Path=@(); Container=@()}
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Enabled=$true}
        }
        Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{OutputVerbosity='Detailed'; OutputRenderMode='Plaintext'} -ExecutionOption @{
            OutputVerbosity = 'Detailed'
            OutputRenderMode = 'Plaintext'
        }
        $config.Output.Verbosity | Should -Be 'Detailed'
        $config.Output.RenderMode | Should -Be 'Plaintext'
        $config.TestResult.Enabled | Should -BeFalse
    }

    It 'leaves Output untouched when nothing is bound' {
        $config = [pscustomobject]@{
            Run = [pscustomobject]@{Path=@(); Container=@()}
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Enabled=$true}
        }
        Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{} -ExecutionOption @{}
        $config.Output.Verbosity | Should -Be 'Default'
        $config.Output.RenderMode | Should -Be 'Default'
        $config.TestResult.Enabled | Should -BeFalse
    }

    It 'does not touch TestResult when it has no Enabled property' {
        $config = [pscustomobject]@{
            Run = [pscustomobject]@{Path=@(); Container=@()}
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Other='x'}
        }
        { Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{} -ExecutionOption @{} } | Should -Not -Throw
    }

    It 'converts Nova-owned run paths to container runs and overlays the approved container override' {
        $scenario = New-NovaPesterExecutionConfigurationScenario -TestFileName @('Alpha.Tests.ps1', 'Beta.Tests.ps1')
        $testPathA = $scenario.TestPath[0]
        $testPathB = $scenario.TestPath[1]
        $providedContainer = New-PesterContainer -Path $testPathA -Data @{ Credential = 'placeholder' }

        Initialize-NovaPesterExecutionConfiguration -PesterConfig $scenario.Config -BoundParameters @{} -ExecutionOption (New-NovaPesterExecutionConfigurationExecutionOption -ProjectPath $scenario.ProjectPath -Container $providedContainer)

        $scenario.Config.Run.Path.Value | Should -BeNullOrEmpty
        $scenario.Config.Run.Container.Value | Should -HaveCount 2
        $scenario.Config.Run.Container.Value[0] | Should -Be $providedContainer
        $scenario.Config.Run.Container.Value[1].Item | Should -Be $testPathB
        $scenario.Config.Run.Container.Value[1].Data.Count | Should -Be 0
    }

    It 'fails fast when a disallowed override path is provided' {
        $config = [pscustomobject]@{
            Run = [pscustomobject]@{Path=@(); Container=@()}
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Enabled=$true}
        }

        {
            Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{} -ExecutionOption @{
                PesterConfigurationOverride = @{
                    Output = @{
                        Verbosity = 'Diagnostic'
                    }
                }
            }
        } | Should -Throw '*Unsupported override path: Output*'
    }

    It 'fails fast when <Name>' -TestCases @(
        @{
            Name = 'Run does not provide any containers'
            Override = @{
                Run = @{}
            }
            ExpectedMessage = '*Provide one or more file-backed containers*'
        }
        @{
            Name = 'Run.Container is empty'
            Override = @{
                Run = @{
                    Container = @()
                }
            }
            ExpectedMessage = '*Provide one or more file-backed containers*'
        }
        @{
            Name = 'a file-backed container does not expose an Item path'
            Override = @{
                Run = [pscustomobject]@{
                    Container = @(
                        [pscustomobject]@{
                            Type = 'File'
                            Data = $null
                        }
                    )
                }
            }
            ExpectedMessage = '*must expose a file path in the Item property*'
        }
        @{
            Name = 'a relative container path does not exist'
            Override = @{
                Run = @{
                    Container = @(
                        [pscustomobject]@{
                            Type = 'File'
                            Item = 'tests/Missing.Tests.ps1'
                            Data = $null
                        }
                    )
                }
            }
            ExpectedMessage = '*path does not exist*'
        }
    ) {
        param($Override, $ExpectedMessage)

        $scenario = New-NovaPesterExecutionConfigurationScenario
        Assert-NovaPesterExecutionConfigurationOverrideFailure -Config $scenario.Config -ProjectPath $scenario.ProjectPath -Override $Override -ExpectedMessage $ExpectedMessage
    }

    It 'resolves relative container paths against ProjectRoot' {
        $scenario = New-NovaPesterExecutionConfigurationScenario
        $relativePath = [System.IO.Path]::GetRelativePath($scenario.ProjectPath, $scenario.TestPath[0])
        $providedContainer = New-PesterContainer -Path $scenario.TestPath[0]
        $providedContainer.Item = $relativePath

        Initialize-NovaPesterExecutionConfiguration -PesterConfig $scenario.Config -BoundParameters @{} -ExecutionOption (
            New-NovaPesterExecutionConfigurationExecutionOption -ProjectPath $scenario.ProjectPath -Container $providedContainer
        )

        $scenario.Config.Run.Container.Value | Should -HaveCount 1
        $scenario.Config.Run.Container.Value[0] | Should -Be $providedContainer
    }

    It 'fails fast when a container points outside the Nova-discovered unit-test set' {
        $projectPath = Join-Path $TestDrive 'project'
        $testPath = Join-Path $projectPath 'tests/Alpha.Tests.ps1'
        $otherPath = Join-Path $projectPath 'tests/Other.Tests.ps1'
        New-Item -ItemType Directory -Path (Split-Path -Parent $testPath) -Force | Out-Null
        Set-Content -LiteralPath $testPath -Value '# alpha'
        Set-Content -LiteralPath $otherPath -Value '# other'

        $config = [pscustomobject]@{
            Run = [pscustomobject]@{
                Path = @($testPath)
                Container = @()
            }
            Output = [pscustomobject]@{Verbosity='Default'; RenderMode='Default'}
            TestResult = [pscustomobject]@{Enabled=$true}
        }

        {
            Initialize-NovaPesterExecutionConfiguration -PesterConfig $config -BoundParameters @{} -ExecutionOption @{
                PesterConfigurationOverride = @{
                    Run = @{
                        Container = @(
                            [pscustomobject]@{
                                Type = 'File'
                                Item = $otherPath
                                Data = @{}
                            }
                        )
                    }
                }
                ProjectRoot = $projectPath
            }
        } | Should -Throw '*Unsupported container path*'
    }

    It 'fails fast when the override contains duplicate containers for the same resolved test path' {
        $scenario = New-NovaPesterExecutionConfigurationScenario

        {
            Initialize-NovaPesterExecutionConfiguration -PesterConfig $scenario.Config -BoundParameters @{} -ExecutionOption (
                New-NovaPesterExecutionConfigurationExecutionOption -ProjectPath $scenario.ProjectPath -Container @(
                    (New-PesterContainer -Path $scenario.TestPath[0] -Data @{ Name = 'first' })
                    (New-PesterContainer -Path $scenario.TestPath[0] -Data @{ Name = 'second' })
                )
            )
        } | Should -Throw '*multiple containers for the same test path*'
    }

    It 'fails fast when the override contains a non-file container type' {
        $scenario = New-NovaPesterExecutionConfigurationScenario

        {
            Initialize-NovaPesterExecutionConfiguration -PesterConfig $scenario.Config -BoundParameters @{} -ExecutionOption (
                New-NovaPesterExecutionConfigurationExecutionOption -ProjectPath $scenario.ProjectPath -Container (New-PesterContainer -ScriptBlock {})
            )
        } | Should -Throw '*ScriptBlock and other container types are not supported*'
    }

    It 'returns empty metadata when override helper inputs are null' {
        $propertyNames = Get-NovaPesterOverridePropertyName -InputObject $null
        $value = Get-NovaPesterOverrideValue -InputObject $null -Name 'Container'

        $propertyNames | Should -HaveCount 0
        $value | Should -BeNullOrEmpty
    }
}
