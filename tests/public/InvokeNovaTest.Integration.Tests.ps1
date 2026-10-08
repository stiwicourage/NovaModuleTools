BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:exampleProjectRoot = Join-Path $script:projectRoot 'src/resources/example'
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

function script:New-NovaInvokeNovaTestIntegrationWorkspace {
    [CmdletBinding()]
    param(
        [switch]$FailProjectB
    )

    $workspaceRoot = Join-Path $TestDrive ([guid]::NewGuid().Guid)
    $projectARoot = Join-Path $workspaceRoot 'ProjectA'
    $projectBRoot = Join-Path $workspaceRoot 'ProjectB'
    New-Item -ItemType Directory -Path $projectARoot -Force | Out-Null
    New-Item -ItemType Directory -Path $projectBRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $script:exampleProjectRoot '*') -Destination $projectARoot -Recurse -Force
    Copy-Item -Path (Join-Path $script:exampleProjectRoot '*') -Destination $projectBRoot -Recurse -Force

    Initialize-NovaInvokeNovaTestIntegrationProject -ProjectRoot $projectARoot -ProjectName 'ProjectA'
    Initialize-NovaInvokeNovaTestIntegrationProject -ProjectRoot $projectBRoot -ProjectName 'ProjectB' -FailCoverage:$FailProjectB

    return [pscustomobject]@{
        WorkspaceRoot = $workspaceRoot
        ProjectARoot = $projectARoot
        ProjectBRoot = $projectBRoot
        ProjectAArtifacts = Get-NovaInvokeNovaTestArtifactPathMap -ProjectRoot $projectARoot
        ProjectBArtifacts = Get-NovaInvokeNovaTestArtifactPathMap -ProjectRoot $projectBRoot
    }
}

function script:Initialize-NovaInvokeNovaTestIntegrationProject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ProjectName,
        [switch]$FailCoverage
    )

    $projectJsonPath = Join-Path $ProjectRoot 'project.json'
    $projectData = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
    $projectData.ProjectName = $ProjectName
    if ($FailCoverage) {
        $projectData.Pester.CodeCoverage.CoveragePercentTarget = 100
    }

    $projectData | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $projectJsonPath

    $artifactsDir = Join-Path $ProjectRoot 'artifacts'
    New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $artifactsDir 'coverage.xml') -Value "sentinel-$ProjectName-coverage"
    Set-Content -LiteralPath (Join-Path $artifactsDir 'UnitTestResults.xml') -Value "sentinel-$ProjectName-results"

    if (-not $FailCoverage) {
        return
    }

    $uncoveredPath = Join-Path $ProjectRoot 'src/private/GetUncoveredValue.ps1'
    Set-Content -LiteralPath $uncoveredPath -Value @'
function Get-UncoveredValue {
    return 'uncovered'
}
'@
}

function script:Get-NovaInvokeNovaTestArtifactPathMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    return [pscustomobject]@{
        CoveragePath = Join-Path $ProjectRoot 'artifacts/coverage.xml'
        TestResultPath = Join-Path $ProjectRoot 'artifacts/UnitTestResults.xml'
    }
}

function script:Assert-NovaInvokeNovaTestSiblingArtifactsRemainUntouched {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Workspace
    )

    (Get-Content -LiteralPath $Workspace.ProjectAArtifacts.CoveragePath -Raw) | Should -Be "sentinel-ProjectA-coverage$([Environment]::NewLine)"
    (Get-Content -LiteralPath $Workspace.ProjectAArtifacts.TestResultPath -Raw) | Should -Be "sentinel-ProjectA-results$([Environment]::NewLine)"
}

function script:Assert-NovaInvokeNovaTestSelectedProjectProducedResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Workspace
    )

    (Get-Content -LiteralPath $Workspace.ProjectBArtifacts.TestResultPath -Raw) | Should -Not -Match 'sentinel-ProjectB-results'
}

Describe 'Invoke-NovaTest integration' {
    It 'supports WhatIf from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            Invoke-NovaTest -WhatIf
        }

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
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

        $outputText = Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace
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

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
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
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match 'ScriptBlock and other container types are not supported'
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
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match 'Unsupported override path: Run.Path'
    }

    It 'writes coverage and test-result artifacts to the selected project when started in that project root' {
        $workspace = New-NovaInvokeNovaTestIntegrationWorkspace

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $workspace.ProjectBRoot -ScriptBlock {
            Invoke-NovaTest
        }

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match 'Covered 100% / 90%'
        (Get-Content -LiteralPath $workspace.ProjectBArtifacts.TestResultPath -Raw) | Should -Not -Match 'sentinel-ProjectB-results'
    }

    It 'keeps artifacts isolated when the session starts in a sibling project and navigates with Set-Location' {
        $workspace = New-NovaInvokeNovaTestIntegrationWorkspace

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $workspace.ProjectARoot -ScriptBlock {
            Set-Location ../ProjectB
            Invoke-NovaTest
        }

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match 'Covered 100% / 90%'
        Assert-NovaInvokeNovaTestSiblingArtifactsRemainUntouched -Workspace $workspace
        Assert-NovaInvokeNovaTestSelectedProjectProducedResults -Workspace $workspace
    }

    It 'resolves the selected project from a parent directory and keeps sequential runs isolated in one session' {
        $workspace = New-NovaInvokeNovaTestIntegrationWorkspace

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $workspace.WorkspaceRoot -ScriptBlock {
            Set-Location ./ProjectA
            Invoke-NovaTest
            Set-Location ../ProjectB
            Invoke-NovaTest
        }

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match 'Covered 100% / 90%.*Covered 100% / 90%'
        (Get-Content -LiteralPath $workspace.ProjectAArtifacts.TestResultPath -Raw) | Should -Not -Match 'sentinel-ProjectA-results'
        (Get-Content -LiteralPath $workspace.ProjectBArtifacts.TestResultPath -Raw) | Should -Not -Match 'sentinel-ProjectB-results'
    }

    It 'keeps failures and artifacts scoped to the selected project when coverage does not meet the configured target' {
        $workspace = New-NovaInvokeNovaTestIntegrationWorkspace -FailProjectB

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $workspace.ProjectARoot -ScriptBlock {
            Set-Location ../ProjectB
            Invoke-NovaTest
        }

        $result.ExitCode | Should -Not -Be 0
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match 'Code coverage .* did not meet the configured target 100%'
        Assert-NovaInvokeNovaTestSiblingArtifactsRemainUntouched -Workspace $workspace
        Assert-NovaInvokeNovaTestSelectedProjectProducedResults -Workspace $workspace
    }
}
