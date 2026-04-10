BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    $distModuleDir = Join-Path $repoRoot "dist/$script:moduleName"
    if (-not (Test-Path -LiteralPath $distModuleDir)) {
        throw "Expected built $script:moduleName module at: $distModuleDir. Run Invoke-MTBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $distModuleDir -Force
}

Describe 'Nova command model' {
    It 'Get-NovaProjectInfo -Version returns only version' {
        InModuleScope $script:moduleName {
            Mock Get-MTProjectInfo {[pscustomobject]@{Version = '9.9.9'; ProjectName = 'X'}}

            Get-NovaProjectInfo -Version | Should -Be '9.9.9'
            Assert-MockCalled Get-MTProjectInfo -Times 1
        }
    }

    It 'Invoke-NovaBuild delegates to Invoke-MTBuild' {
        InModuleScope $script:moduleName {
            Mock Invoke-MTBuild {}

            Invoke-NovaBuild

            Assert-MockCalled Invoke-MTBuild -Times 1
        }
    }

    It 'Test-NovaBuild forwards tag filters to Invoke-MTTest' {
        InModuleScope $script:moduleName {
            Mock Invoke-MTTest {}

            Test-NovaBuild -TagFilter @('fast') -ExcludeTagFilter @('slow')

            Assert-MockCalled Invoke-MTTest -Times 1 -ParameterFilter {
                $TagFilter -eq 'fast' -and $ExcludeTagFilter -eq 'slow'
            }
        }
    }

    It 'Invoke-NovaRelease runs build test bump build publish in order' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Update-NovaModuleVersion {
                $script:steps += 'bump'
                return [pscustomobject]@{NewVersion = '1.0.1'}
            }
            Mock Publish-NovaBuiltModule {$script:steps += 'publish'}

            Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path | Out-Null

            $script:steps -join ',' | Should -Be 'build,test,bump,build,publish'
        }
    }

    It 'Invoke-NovaRelease does not bump version when tests fail' {
        InModuleScope $script:moduleName {
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {throw 'boom'}
            Mock Update-NovaModuleVersion {}

            {Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path} | Should -Throw
            Assert-MockCalled Update-NovaModuleVersion -Times 0
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


