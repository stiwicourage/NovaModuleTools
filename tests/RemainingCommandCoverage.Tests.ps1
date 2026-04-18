BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
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

    It 'Test-NovaBuild creates the artifacts directory when it is missing' {
        $cfg = [pscustomobject]@{
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
                OutputPath = $null
            }
        }

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            $projectRoot = '/tmp/nova-project'

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
            Mock Test-Path {$false}
            Mock New-Item {}
            Mock Invoke-Pester {[pscustomobject]@{Result = 'Passed'}}

            Test-NovaBuild

            $Config.Run.Path | Should -Be ([System.IO.Path]::Join('tests', '*.Tests.ps1'))
            Assert-MockCalled New-Item -Times 1 -ParameterFilter {
                $ItemType -eq 'Directory' -and $Path -eq ([System.IO.Path]::Join($projectRoot, 'artifacts')) -and $Force
            }
        }
    }

    It 'Test-NovaBuild throws when Pester reports a failing result' {
        $cfg = [pscustomobject]@{
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
                OutputPath = $null
            }
        }

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            Mock Test-ProjectSchema {}
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Pester = @{}
                    BuildRecursiveFolders = $true
                    TestsDir = 'tests'
                    ProjectRoot = '/tmp/nova-project'
                }
            }
            Mock New-PesterConfiguration {$Config}
            Mock Test-Path {$true}
            Mock Invoke-Pester {[pscustomobject]@{Result = 'Failed'}}

            {Test-NovaBuild} | Should -Throw 'Tests failed'
        }
    }

    It 'Test-NovaBuild resolves and invokes the private test result report writer when Pester returns tests' {
        $cfg = [pscustomobject]@{
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
                OutputPath = $null
            }
        }

        InModuleScope $script:moduleName -Parameters @{Config = $cfg} {
            param($Config)

            $script:reportWasWritten = $false
            $projectRoot = '/tmp/nova-project'
            $reportWriter = {
                param($TestResult, $OutputPath, $ReportWriter)

                $script:reportWasWritten = $null -ne $TestResult -and $OutputPath -eq [System.IO.Path]::Join($projectRoot, 'artifacts', 'TestResults.xml')
            }

            Mock Test-ProjectSchema {}
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    Pester = @{}
                    BuildRecursiveFolders = $true
                    TestsDir = 'tests'
                    ProjectRoot = $projectRoot
                }
            }
            Mock New-PesterConfiguration {$Config}
            Mock Test-Path {$true}
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $reportWriter}
            } -ParameterFilter {$Name -eq 'Write-NovaPesterTestResultArtifact' -and $CommandType -eq 'Function'}
            Mock Invoke-Pester {[pscustomobject]@{Result = 'Passed'; Tests = @([pscustomobject]@{Result = 'Passed'})}}

            Test-NovaBuild

            $script:reportWasWritten | Should -BeTrue
            Assert-MockCalled Get-Command -Times 1 -ParameterFilter {$Name -eq 'Write-NovaPesterTestResultArtifact' -and $CommandType -eq 'Function'}
        }
    }

    It 'Install-NovaCli rejects Windows hosts explicitly' {
        InModuleScope $script:moduleName {
            try {
                Set-Variable -Name IsWindows -Value $true -Force

                {Install-NovaCli} | Should -Throw 'Install-NovaCli currently supports macOS/Linux only*'
            }
            finally {
                Remove-Variable -Name IsWindows -Force -ErrorAction SilentlyContinue
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

                {Install-NovaCli} | Should -Throw 'Target file already exists: /tmp/bin/nova*'
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
            {Invoke-NovaCli banana} | Should -Throw 'Unknown command: <banana*'
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
