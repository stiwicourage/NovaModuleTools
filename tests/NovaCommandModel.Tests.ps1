BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    $distModuleDir = Join-Path $repoRoot "dist/$script:moduleName"
    if (-not (Test-Path -LiteralPath $distModuleDir)) {
        throw "Expected built $script:moduleName module at: $distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $distModuleDir -Force
}

Describe 'Nova command model' {
    It 'Get-NovaProjectInfo -Version returns only version' {
        InModuleScope $script:moduleName {
            Mock Get-Content {'{"ProjectName":"X","Version":"9.9.9"}'}

            (Get-NovaProjectInfo).Version | Should -Be '9.9.9'
        }
    }

    It 'Invoke-NovaBuild runs module build pipeline' {
        InModuleScope $script:moduleName {
            Mock Reset-ProjectDist {}
            Mock Build-Module {}
            Mock Get-NovaProjectInfo {[pscustomobject]@{FailOnDuplicateFunctionNames = $false}}
            Mock Build-Manifest {}
            Mock Build-Help {}
            Mock Copy-ProjectResource {}

            Invoke-NovaBuild

            Assert-MockCalled Build-Module -Times 1
        }
    }

    It 'Test-NovaBuild applies tag filters to Pester config' {
        InModuleScope $script:moduleName {
            $cfg = [pscustomobject]@{
                Run = [pscustomobject]@{Path = $null; PassThru = $false; Exit = $false; Throw = $false}
                Filter = [pscustomobject]@{Tag = @(); ExcludeTag = @()}
                TestResult = [pscustomobject]@{OutputPath = $null}
            }

            Mock Test-ProjectSchema {}
            Mock Get-NovaProjectInfo {[pscustomobject]@{Pester = @{}; BuildRecursiveFolders = $true; TestsDir = 'tests'}}
            Mock New-PesterConfiguration {$cfg}
            Mock Invoke-Pester {[pscustomobject]@{Result = 'Passed'}}

            Test-NovaBuild -TagFilter @('fast') -ExcludeTagFilter @('slow')

            $cfg.Filter.Tag | Should -Be @('fast')
            $cfg.Filter.ExcludeTag | Should -Be @('slow')
        }
    }

    It 'Invoke-NovaRelease runs build test bump build publish in order' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Update-NovaModuleVersion {
                $script:steps += 'bump'
                return [pscustomobject]@{NewVersion = '1.0.1'}
            }
            Mock Test-Path {$true}
            Mock Remove-Item {}
            Mock Copy-Item {$script:steps += 'publish'}

            Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path | Out-Null

            $script:steps -join ',' | Should -Be 'build,test,bump,build,publish'
        }
    }

    It 'Invoke-NovaRelease does not bump version when tests fail' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {throw 'boom'}
            Mock Update-NovaModuleVersion {}

            {Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path} | Should -Throw
            Assert-MockCalled Update-NovaModuleVersion -Times 0
        }
    }

    It 'Publish-NovaModule resolves local path before tests can reload helpers' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {
                $script:steps += 'resolve'
                '/tmp/modules'
            }
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {
                $script:steps += 'test'
                Remove-Item function:Get-LocalModulePath -ErrorAction SilentlyContinue
            }
            Mock Test-Path {$true}
            Mock Remove-Item {}
            Mock Copy-Item {$script:steps += 'copy'}

            {Publish-NovaModule -Local} | Should -Not -Throw

            $script:steps -join ',' | Should -Be 'resolve,build,test,copy'
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Destination -eq '/tmp/modules'}
        }
    }

    It 'Get-ResourceFilePath prefers project src resources during build' {
        InModuleScope $script:moduleName {
            $expected = [System.IO.Path]::GetFullPath('/tmp/project/src/resources/Schema-Build.json')
            $script:checkedPaths = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ResourcesDir = '/tmp/project/src/resources'
                }
            }
            Mock Test-Path {
                param($LiteralPath)

                $script:checkedPaths += $LiteralPath
                return $LiteralPath -eq $expected
            }

            $result = Get-ResourceFilePath -FileName 'Schema-Build.json'

            $result | Should -Be $expected
            $script:checkedPaths[0] | Should -Be $expected
        }
    }

    It 'built module keeps Publish-NovaModule local path resolution before build and test' {
        $packagedModulePath = (Get-Module $script:moduleName).Path

        Test-Path -LiteralPath $packagedModulePath | Should -BeTrue

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($packagedModulePath, [ref]$tokens, [ref]$errors)

        $errors.Count | Should -Be 0

        $publishFunction = $ast.Find(
                {
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                            $node.Name -eq 'Publish-NovaModule'
                },
                $true
        )

        $publishFunction | Should -Not -BeNullOrEmpty
        $publishSource = $publishFunction.Extent.Text

        $publishSource.IndexOf('$PSBoundParameters.ContainsKey(''Repository'')') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Get-LocalModulePath') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Invoke-NovaBuild') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Get-LocalModulePath') | Should -BeLessThan $publishSource.IndexOf('Invoke-NovaBuild')
    }

    It 'Update-NovaModuleVersion -WhatIf does not invoke Set-NovaModuleVersion' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Version = '1.0.0'
                    ProjectJSON = '/tmp/project.json'
                }
            }
            Mock Get-GitCommitMessageForVersionBump {@('feat: add change')}
            Mock Get-VersionLabelFromCommitSet {'Minor'}
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path (Get-Location).Path -WhatIf

            $result.PreviousVersion | Should -Be '1.0.0'
            $result.NewVersion | Should -Be '1.0.0'
            $result.Label | Should -Be 'Minor'
            Assert-MockCalled Set-NovaModuleVersion -Times 0
        }
    }

    It 'Invoke-NovaCli version maps to Get-NovaProjectInfo -Version' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {'1.2.3'} -ParameterFilter {$Version}

            Invoke-NovaCli version | Should -Be '1.2.3'
            Assert-MockCalled Get-NovaProjectInfo -Times 1 -ParameterFilter {$Version}
        }
    }

    It 'Invoke-NovaCli publish forwards repository options' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                return [pscustomobject]@{
                    Repository = $Repository
                    ApiKey = $ApiKey
                }
            }

            $result = Invoke-NovaCli publish --repository PSGallery --apikey key123

            $result.Repository | Should -Be 'PSGallery'
            $result.ApiKey | Should -Be 'key123'
        }
    }

    It 'Invoke-NovaCli throws on unsupported argument' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli publish --bogus} | Should -Throw 'Unknown argument*'
        }
    }
}


