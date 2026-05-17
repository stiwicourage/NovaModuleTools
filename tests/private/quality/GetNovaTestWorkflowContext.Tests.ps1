BeforeAll {
    $script:repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force

    $script:getTestQualityPesterConfig = {
        return [pscustomobject]@{
            Run = [pscustomobject]@{
                Path = $null
                PassThru = $false
                Exit = $false
                Throw = $false
            }
            Filter = [pscustomobject]@{
                Tag = @()
                ExcludeTag = @()
            }
            Output = [pscustomobject]@{
                Verbosity = 'Detailed'
                RenderMode = 'Auto'
            }
            TestResult = [pscustomobject]@{
                Enabled = $true
                OutputPath = $null
            }
            CodeCoverage = [pscustomobject]@{
                Enabled = $true
                CoveragePercentTarget = 80
                Path = $null
            }
        }
    }

    $script:getTestQualityProjectInfo = {
        param(
            [Parameter(Mandatory)]
            [object]$PesterSettings
        )

        return [pscustomobject]@{
            Pester = $PesterSettings
            BuildRecursiveFolders = $false
            TestsDir = 'tests'
            ProjectRoot = '/tmp/nova-project'
            ModuleFilePSM1 = '/tmp/nova-project/dist/TestProject/TestProject.psm1'
        }
    }
}

Describe 'Get-NovaTestWorkflowContext' {
    It 'applies CoveragePercentTarget from project.json to the Pester configuration' {
        $pesterConfig = & $script:getTestQualityPesterConfig
        $projectInfo = & $script:getTestQualityProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                CoveragePercentTarget = 99
            }
        })

        InModuleScope $script:moduleName -Parameters @{
            PesterConfig = $pesterConfig
            ProjectInfo = $projectInfo
        } {
            param($PesterConfig, $ProjectInfo)

            $writer = [pscustomobject]@{ScriptBlock = {}}

            Mock Test-ProjectSchema {}
            Mock Get-Module {
                [pscustomobject]@{Name = 'Pester'}
            } -ParameterFilter {
                $Name -eq 'Pester' -and $ListAvailable
            }
            Mock Get-NovaProjectInfo { $ProjectInfo }
            Mock New-PesterConfiguration { $PesterConfig }
            Mock Get-Command { $writer } -ParameterFilter {
                $CommandType -eq 'Function'
            }

            $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

            $result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 99
        }
    }

    It 'keeps the default Pester coverage target when project.json omits CoveragePercentTarget' {
        $pesterConfig = & $script:getTestQualityPesterConfig
        $projectInfo = & $script:getTestQualityProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
            }
        })

        InModuleScope $script:moduleName -Parameters @{
            PesterConfig = $pesterConfig
            ProjectInfo = $projectInfo
        } {
            param($PesterConfig, $ProjectInfo)

            $writer = [pscustomobject]@{ScriptBlock = {}}

            Mock Test-ProjectSchema {}
            Mock Get-Module {
                [pscustomobject]@{Name = 'Pester'}
            } -ParameterFilter {
                $Name -eq 'Pester' -and $ListAvailable
            }
            Mock Get-NovaProjectInfo { $ProjectInfo }
            Mock New-PesterConfiguration { $PesterConfig }
            Mock Get-Command { $writer } -ParameterFilter {
                $CommandType -eq 'Function'
            }

            $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

            $result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 80
        }
    }

    It 'sets CodeCoverage.Path to the built module psm1 when coverage is enabled' {
        $pesterConfig = & $script:getTestQualityPesterConfig
        $projectInfo = & $script:getTestQualityProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                CoveragePercentTarget = 90
            }
        })

        InModuleScope $script:moduleName -Parameters @{
            PesterConfig = $pesterConfig
            ProjectInfo = $projectInfo
        } {
            param($PesterConfig, $ProjectInfo)

            $writer = [pscustomobject]@{ScriptBlock = {}}

            Mock Test-ProjectSchema {}
            Mock Get-Module {
                [pscustomobject]@{Name = 'Pester'}
            } -ParameterFilter {
                $Name -eq 'Pester' -and $ListAvailable
            }
            Mock Get-NovaProjectInfo { $ProjectInfo }
            Mock New-PesterConfiguration { $PesterConfig }
            Mock Get-Command { $writer } -ParameterFilter {
                $CommandType -eq 'Function'
            }

            $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

            $result.PesterConfig.CodeCoverage.Path | Should -Be '/tmp/nova-project/dist/TestProject/TestProject.psm1'
        }
    }

    It 'does not set CodeCoverage.Path when coverage is disabled' {
        $pesterConfig = & $script:getTestQualityPesterConfig
        $projectInfo = & $script:getTestQualityProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $false
            }
        })

        InModuleScope $script:moduleName -Parameters @{
            PesterConfig = $pesterConfig
            ProjectInfo = $projectInfo
        } {
            param($PesterConfig, $ProjectInfo)

            $writer = [pscustomobject]@{ScriptBlock = {}}

            Mock Test-ProjectSchema {}
            Mock Get-Module {
                [pscustomobject]@{Name = 'Pester'}
            } -ParameterFilter {
                $Name -eq 'Pester' -and $ListAvailable
            }
            Mock Get-NovaProjectInfo { $ProjectInfo }
            Mock New-PesterConfiguration { $PesterConfig }
            Mock Get-Command { $writer } -ParameterFilter {
                $CommandType -eq 'Function'
            }

            $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

            $result.PesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
        }
    }
}
