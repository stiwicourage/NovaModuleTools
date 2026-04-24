BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"
    $remainingCommandCoverageTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'RemainingCommandCoverage.TestSupport.ps1')).Path
    $remainingCommandCoverageTestSupportFunctionNameList = @(
        'Get-TestNovaPesterConfig'
        'Get-TestNovaTestWorkflowContext'
        'Get-TestNovaPesterWorkflowReportContext'
        'Get-TestNovaPesterArtifactWriter'
        'Get-TestNovaPesterReportWriter'
    )

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $remainingCommandCoverageTestSupportPath
    foreach ($functionName in $remainingCommandCoverageTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage for remaining command and filesystem branches' {
    It 'Reset-ProjectDist removes an existing output directory and recreates the dist folders' {
        $outputDir = Join-Path $TestDrive 'dist'
        $outputModuleDir = Join-Path $outputDir 'NovaModuleTools'
        New-Item -ItemType Directory -Path $outputModuleDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $outputDir 'stale.txt') -Value 'stale' -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{OutputDir = $outputDir; OutputModuleDir = $outputModuleDir} {
            param($OutputDir, $OutputModuleDir)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    OutputDir = $OutputDir
                    OutputModuleDir = $OutputModuleDir
                }
            }

            Reset-ProjectDist
        }

        (Test-Path -LiteralPath $outputDir -PathType Container) | Should -BeTrue
        (Test-Path -LiteralPath $outputModuleDir -PathType Container) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $outputDir 'stale.txt')) | Should -BeFalse
    }

    It 'Reset-ProjectDist wraps filesystem failures with a clear error' {
        $outputDir = Join-Path $TestDrive 'dist-error'
        $outputModuleDir = Join-Path $outputDir 'NovaModuleTools'

        InModuleScope $script:moduleName -Parameters @{OutputDir = $outputDir; OutputModuleDir = $outputModuleDir} {
            param($OutputDir, $OutputModuleDir)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    OutputDir = $OutputDir
                    OutputModuleDir = $OutputModuleDir
                }
            }
            Mock Test-Path {$false}
            Mock New-Item {throw 'access denied'} -ParameterFilter {$Path -eq $OutputDir}

            {Reset-ProjectDist} | Should -Throw 'Failed to reset Dist folder: access denied'
        }
    }

    It 'New-InitiateGitRepo warns when a repository already exists in the target directory' {
        $repoPath = Join-Path $TestDrive 'existing-git-repo'
        New-Item -ItemType Directory -Path (Join-Path $repoPath '.git') -Force | Out-Null

        InModuleScope $script:moduleName -Parameters @{RepoPath = $repoPath} {
            param($RepoPath)

            Mock Get-Command {[pscustomobject]@{Name = 'git'}} -ParameterFilter {$Name -eq 'git'}
            Mock Write-Warning {}

            New-InitiateGitRepo -DirectoryPath $RepoPath -Confirm:$false

            Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {
                $Message -eq 'A Git repository already exists in this directory.'
            }
        }
    }

    It 'New-InitiateGitRepo wraps git init failures with a clear error' {
        $repoPath = Join-Path $TestDrive 'failing-git-repo'
        New-Item -ItemType Directory -Path $repoPath -Force | Out-Null

        function global:git {
            throw 'init failed'
        }

        try {
            InModuleScope $script:moduleName -Parameters @{RepoPath = $repoPath} {
                param($RepoPath)

                {New-InitiateGitRepo -DirectoryPath $RepoPath -Confirm:$false} | Should -Throw 'Failed to initialize Git repo: init failed'
            }
        }
        finally {
            Remove-Item -Path function:global:git -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Get-NovaTestWorkflowContext prepares the Pester workflow state and resolves the report writers' {
        $cfg = Get-TestNovaPesterConfig

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            $projectRoot = '/tmp/nova-project'
            $artifactWriter = [pscustomobject]@{ScriptBlock = {}}
            $reportWriter = [pscustomobject]@{ScriptBlock = {}}

            Mock Test-ProjectSchema {}
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Pester = @{}
                    BuildRecursiveFolders = $false
                    TestsDir = 'tests'
                    ProjectRoot = $projectRoot
                }
            }
            Mock New-PesterConfiguration {$Config}
            Mock Get-Command {$artifactWriter} -ParameterFilter {$Name -eq 'Write-NovaPesterTestResultArtifact' -and $CommandType -eq 'Function'}
            Mock Get-Command {$reportWriter} -ParameterFilter {$Name -eq 'Write-NovaPesterTestResultReport' -and $CommandType -eq 'Function'}

            $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

            $result.Target | Should -Be ([System.IO.Path]::Join($projectRoot, 'artifacts', 'TestResults.xml'))
            $result.Operation | Should -Be 'Run Pester tests and write test results'
            $Config.Run.Path | Should -Be ([System.IO.Path]::Join('tests', '*.Tests.ps1'))
            $Config.Output.RenderMode | Should -Be 'Auto'
            $result.TestResultArtifactWriter | Should -Be $artifactWriter
            $result.TestResultReportWriter | Should -Be $reportWriter
        }
    }

    It 'Invoke-NovaTestWorkflow creates the artifacts directory when it is missing' {
        $cfg = Get-TestNovaPesterConfig

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            $workflowContext = Get-TestNovaTestWorkflowContext -Config $Config -ProjectRoot '/tmp/nova-project' -ArtifactWriter {} -ReportWriter {}

            Mock Test-Path {$false}
            Mock New-Item {}
            Mock Invoke-NovaPester {[pscustomobject]@{Result = 'Passed'}}

            Invoke-NovaTestWorkflow -WorkflowContext $workflowContext

            Assert-MockCalled New-Item -Times 1 -ParameterFilter {
                $ItemType -eq 'Directory' -and $Path -eq '/tmp/nova-project/artifacts' -and $Force
            }
            $Config.TestResult.OutputPath | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
        }
    }

    It 'Invoke-NovaTestWorkflow throws when Pester reports a failing result' {
        $cfg = Get-TestNovaPesterConfig

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            $workflowContext = Get-TestNovaTestWorkflowContext -Config $Config -ProjectRoot '/tmp/nova-project' -ArtifactWriter {} -ReportWriter {}

            Mock Test-Path {$true}
            Mock Invoke-NovaPester {[pscustomobject]@{Result = 'Failed'}}

            {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Throw 'Tests failed'
        }
    }

    It 'Invoke-NovaTestWorkflow resolves and invokes the private test result report writer when Pester returns tests' {
        $cfg = Get-TestNovaPesterConfig

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            $global:reportWasWritten = $false
            $workflowContext = Get-TestNovaPesterWorkflowReportContext -Config $Config -ProjectRoot '/tmp/nova-project'

            Mock Test-Path {$true}
            Mock Invoke-NovaPester {[pscustomobject]@{Result = 'Passed'; Tests = @([pscustomobject]@{Result = 'Passed'})}}

            Invoke-NovaTestWorkflow -WorkflowContext $workflowContext

            $global:reportWasWritten | Should -BeTrue
        }
    }

    It 'Install-NovaCli rejects Windows hosts explicitly' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $true -Force

                $unsupportedPlatformError = $null
                try {
                    Install-NovaCli
                }
                catch {
                    $unsupportedPlatformError = $_
                }

                $unsupportedPlatformError | Should -Not -BeNullOrEmpty
                $unsupportedPlatformError.Exception.Message | Should -BeLike 'Install-NovaCli currently supports macOS/Linux only*'
                $unsupportedPlatformError.FullyQualifiedErrorId | Should -Be 'Nova.Environment.UnsupportedCliInstallPlatform'
                $unsupportedPlatformError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::NotImplemented)
                $unsupportedPlatformError.TargetObject | Should -Be 'Windows'
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Get-NovaCliInstallWorkflowContext resolves launcher install paths and action text' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $false -Force
                Mock Get-NovaCliInstallDirectory {'/tmp/bin'}
                Mock Get-NovaCliLauncherPath {'/tmp/source/nova'}
                Mock Test-Path {$false}

                $result = Get-NovaCliInstallWorkflowContext -DestinationDirectory '/tmp/bin' -Force

                $result.SourcePath | Should -Be '/tmp/source/nova'
                $result.TargetPath | Should -Be '/tmp/bin/nova'
                $result.TargetDirectory | Should -Be '/tmp/bin'
                $result.Force | Should -BeTrue
                $result.Action | Should -Be 'Install nova CLI launcher'
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Invoke-NovaCliInstallWorkflow copies the launcher and shapes the install result' {
        InModuleScope $script:moduleName {
            $workflowContext = [pscustomobject]@{
                SourcePath = '/tmp/source/nova'
                TargetPath = '/tmp/bin/nova'
                TargetDirectory = '/tmp/bin'
                Force = $true
                Action = 'Install nova CLI launcher'
            }
            Mock Copy-NovaCliLauncher {'/tmp/bin/nova'}
            Mock Test-NovaCliDirectoryOnPath {$true}
            Mock Write-NovaModuleReleaseNotesLink {}

            $result = Invoke-NovaCliInstallWorkflow -WorkflowContext $workflowContext

            $result.CommandName | Should -Be 'nova'
            $result.InstalledPath | Should -Be '/tmp/bin/nova'
            $result.DestinationDirectory | Should -Be '/tmp/bin'
            $result.DirectoryOnPath | Should -BeTrue
            Assert-MockCalled Copy-NovaCliLauncher -Times 1 -ParameterFilter {
                $SourcePath -eq '/tmp/source/nova' -and
                        $TargetPath -eq '/tmp/bin/nova' -and
                        $Force
            }
            Assert-MockCalled Write-NovaModuleReleaseNotesLink -Times 1
        }
    }

    It 'Install-NovaCli delegates context resolution and install execution to private helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaCliInstallWorkflowContext {
                [pscustomobject]@{
                    SourcePath = '/tmp/source/nova'
                    TargetPath = '/tmp/bin/nova'
                    TargetDirectory = '/tmp/bin'
                    Force = $true
                    Action = 'Install nova CLI launcher'
                }
            }
            Mock Invoke-NovaCliInstallWorkflow {
                [pscustomobject]@{
                    CommandName = 'nova'
                    InstalledPath = '/tmp/bin/nova'
                    DestinationDirectory = '/tmp/bin'
                    DirectoryOnPath = $true
                }
            }

            $result = Install-NovaCli -DestinationDirectory '/tmp/bin' -Force -Confirm:$false

            $result.InstalledPath | Should -Be '/tmp/bin/nova'
            Assert-MockCalled Get-NovaCliInstallWorkflowContext -Times 1 -ParameterFilter {
                $DestinationDirectory -eq '/tmp/bin' -and $Force
            }
            Assert-MockCalled Invoke-NovaCliInstallWorkflow -Times 1 -ParameterFilter {
                $WorkflowContext.TargetPath -eq '/tmp/bin/nova' -and
                        $WorkflowContext.Action -eq 'Install nova CLI launcher'
            }
        }
    }

    It 'Install-NovaCli throws when the target file exists and Force is not used' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $false -Force
                Mock Get-NovaCliInstallDirectory {'/tmp/bin'}
                Mock Get-NovaCliLauncherPath {'/tmp/source/nova'}
                Mock Test-Path {$true}

                $targetExistsError = $null
                try {
                    Install-NovaCli
                }
                catch {
                    $targetExistsError = $_
                }

                $targetExistsError | Should -Not -BeNullOrEmpty
                $targetExistsError.Exception.Message | Should -BeLike 'Target file already exists: /tmp/bin/nova*'
                $targetExistsError.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.CliInstallTargetExists'
                $targetExistsError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ResourceExists)
                $targetExistsError.TargetObject | Should -Be '/tmp/bin/nova'
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Install-NovaCli returns without copying when WhatIf declines the install action' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $false -Force
                Mock Get-NovaCliInstallDirectory {'/tmp/bin'}
                Mock Get-NovaCliLauncherPath {'/tmp/source/nova'}
                Mock Test-Path {$false}
                Mock Copy-NovaCliLauncher {throw 'should not copy'}

                $result = Install-NovaCli -WhatIf

                $result | Should -BeNullOrEmpty
                Assert-MockCalled Copy-NovaCliLauncher -Times 0
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Install-NovaCli warns when the install directory is not on PATH' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $false -Force
                Mock Get-NovaCliInstallDirectory {'/tmp/bin'}
                Mock Get-NovaCliLauncherPath {'/tmp/source/nova'}
                Mock Test-Path {$false}
                Mock Copy-NovaCliLauncher {'/tmp/bin/nova'}
                Mock Test-NovaCliDirectoryOnPath {$false}
                Mock Write-Warning {}

                $result = Install-NovaCli -Force -Confirm:$false

                $result.InstalledPath | Should -Be '/tmp/bin/nova'
                $result.DirectoryOnPath | Should -BeFalse
                Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {
                    $Message -like 'Installed nova to /tmp/bin, but that directory is not currently in PATH*'
                }
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Install-NovaCli prints the release notes link after a successful install' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $false -Force
                Mock Get-NovaCliInstallDirectory {'/tmp/bin'}
                Mock Get-NovaCliLauncherPath {'/tmp/source/nova'}
                Mock Test-Path {$false}
                Mock Copy-NovaCliLauncher {'/tmp/bin/nova'}
                Mock Test-NovaCliDirectoryOnPath {$true}
                Mock Get-NovaModuleReleaseNotesUri {'https://www.novamoduletools.com/release-notes.html'}
                Mock Write-Host {}

                $result = Install-NovaCli -Force -Confirm:$false

                $result.InstalledPath | Should -Be '/tmp/bin/nova'
                $result.DirectoryOnPath | Should -BeTrue
                Assert-MockCalled Write-Host -Times 1 -ParameterFilter {
                    $Object -eq 'Release notes: https://www.novamoduletools.com/release-notes.html'
                }
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Publish-NovaBuiltModule uses an explicit local module directory without resolving the default path' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                OutputModuleDir = '/tmp/dist/NovaModuleTools'
                ProjectName = 'NovaModuleTools'
            }

            Mock Test-Path {$true}
            Mock Resolve-NovaLocalPublishPath {throw 'should not resolve default path'}
            Mock Publish-NovaBuiltModuleToDirectory {}

            Publish-NovaBuiltModule -ProjectInfo $projectInfo -ModuleDirectoryPath '/tmp/custom-modules'

            Assert-MockCalled Resolve-NovaLocalPublishPath -Times 0
            Assert-MockCalled Publish-NovaBuiltModuleToDirectory -Times 1 -ParameterFilter {
                $ModuleDirectoryPath -eq '/tmp/custom-modules'
            }
        }
    }

    It 'Publish-NovaBuiltModule resolves the default ProjectInfo when none is supplied' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    ProjectName = 'NovaModuleTools'
                }
            }
            Mock Test-Path {$true}
            Mock Resolve-NovaLocalPublishPath {'/tmp/default-modules'}
            Mock Publish-NovaBuiltModuleToDirectory {}

            Publish-NovaBuiltModule

            Assert-MockCalled Get-NovaProjectInfo -Times 1
            Assert-MockCalled Resolve-NovaLocalPublishPath -Times 1 -ParameterFilter {
                $ModuleDirectoryPath -eq ''
            }
            Assert-MockCalled Publish-NovaBuiltModuleToDirectory -Times 1 -ParameterFilter {
                $ModuleDirectoryPath -eq '/tmp/default-modules'
            }
        }
    }

    It 'Invoke-NovaCli throws on an unknown top-level command' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Invoke-NovaCli banana
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -Be "Unknown command: <banana> | Use 'nova --help' to see available commands."
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.UnknownCliCommand'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidArgument)
            $thrown.TargetObject | Should -Be 'banana'
        }
    }

    It 'Invoke-NovaCli version -Installed returns the locally installed version for the current project' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {throw 'should not read project metadata'}
            Mock Get-NovaInstalledProjectVersion {'AzureDevOpsAgentInstaller 1.2.0'}

            Invoke-NovaCli version -Installed | Should -Be 'AzureDevOpsAgentInstaller 1.2.0'
            Assert-MockCalled Get-NovaInstalledProjectVersion -Times 1
            Assert-MockCalled Get-NovaProjectInfo -Times 0 -ParameterFilter {-not $Version}
        }
    }

    It 'Invoke-NovaCli version and version -Installed can differ until a local publish updates the installed module' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'AzureDevOpsAgentInstaller'; Version = '1.12.1'}}
            Mock Get-NovaInstalledProjectVersion {'AzureDevOpsAgentInstaller 1.12.0'}

            (Invoke-NovaCli version) | Should -Be 'AzureDevOpsAgentInstaller 1.12.1'
            (Invoke-NovaCli version -Installed) | Should -Be 'AzureDevOpsAgentInstaller 1.12.0'
        }
    }

    It 'Invoke-NovaCli version -Installed throws a clear error when the current project is not installed locally' {
        InModuleScope $script:moduleName {
            Mock Get-NovaInstalledProjectVersion {throw "Local module install not found for AzureDevOpsAgentInstaller. Expected manifest at: /tmp/modules/AzureDevOpsAgentInstaller/AzureDevOpsAgentInstaller.psd1. Run 'nova publish -local' first."}

            {Invoke-NovaCli version -Installed} | Should -Throw "Local module install not found for AzureDevOpsAgentInstaller*nova publish -local*"
        }
    }
}
