$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
$global:novaCommandModelTestSupportFunctionNameList = @(
    'Get-TestRegexMatchGroup'
    'ConvertTo-TestNormalizedText'
    'Get-TestModuleDisplayVersion'
    'Get-TestHelpLocaleFromMarkdownFiles'
    'Get-CommandHelpActivationTestCase'
    'Get-CommandHelpActivationTestCases'
    'Initialize-TestNovaCliProjectLayout'
    'Write-TestNovaCliProjectJson'
    'Write-TestNovaCliPublicFunction'
    'Initialize-TestNovaCliGitRepository'
    'Invoke-TestInstalledNovaCommand'
    'New-TestPesterConfigStub'
)
. $script:testSupportPath

foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
    $here = Split-Path -Parent $PSCommandPath
    $repoRoot = Split-Path -Parent $here
    $script:projectInfo = Get-NovaProjectInfo -Path $repoRoot
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    $script:distModuleDir = Join-Path $repoRoot "dist/$script:moduleName"
    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
    . $testSupportPath
    foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
}

Describe 'Nova command model - standalone CLI behavior' {
    It 'Install-NovaCli copies the launcher and the installed command returns CLI help' {
        $targetDirectory = Join-Path $TestDrive 'bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $installedModuleVersion = Get-TestModuleDisplayVersion -Module (Get-Module $script:moduleName)
        $expectedProjectVersionText = "$( $script:projectInfo.ProjectName ) $( $script:projectInfo.Version )"
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        try {
            $result = Install-NovaCli -DestinationDirectory $targetDirectory -Force
            $helpOutput = & $installedPath --help 2>&1
            $helpText = @($helpOutput) -join [Environment]::NewLine
            $helpExitCode = $LASTEXITCODE
            $versionOutput = & $installedPath --version 2>&1
            $versionText = @($versionOutput) -join [Environment]::NewLine
            $versionExitCode = $LASTEXITCODE
            Push-Location $script:projectInfo.ProjectRoot
            try {
                $projectVersionOutput = & $installedPath version 2>&1
                $projectVersionText = @($projectVersionOutput) -join [Environment]::NewLine
                $projectVersionExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $result.CommandName | Should -Be 'nova'
            $result.InstalledPath | Should -Be $installedPath
            $result.DestinationDirectory | Should -Be $targetDirectory
            (Test-Path -LiteralPath $installedPath) | Should -BeTrue
            $helpExitCode | Should -Be 0
            $versionExitCode | Should -Be 0
            $projectVersionExitCode | Should -Be 0
            $helpText | Should -Match 'usage: nova \[--version\] \[--help\] <command> \[<args>\]'
            ($helpText -match 'notification\s+Show or change prerelease self-update eligibility') | Should -BeTrue
            $helpText | Should -Match 'version\s+Show the current project version, or use -Installed for the locally installed project module version'
            $helpText | Should -Match 'merge\s+Build, test, and package the module as configured package artifact\(s\)'
            $helpText | Should -Match 'nova deploy -repository LocalNexus'
            $helpText | Should -Not -Match 'nova deploy package'
            $versionText | Should -Be "$script:moduleName $installedModuleVersion"
            $projectVersionText | Should -Be $expectedProjectVersionText
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards -Verbose from the standalone launcher to build output' {
        $targetDirectory = Join-Path $TestDrive 'verbose-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectRoot = Join-Path $TestDrive 'CliVerboseBuildProject'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
        foreach ($dir in @('src/public', 'src/private', 'src/classes', 'src/resources', 'tests', 'docs')) {
            New-Item -ItemType Directory -Path (Join-Path $projectRoot $dir) -Force | Out-Null
        }

        @'
{
  "ProjectName": "CliVerboseBuildProject",
  "Description": "CLI verbose forwarding test project",
  "Version": "0.0.1",
  "CopyResourcesToModuleRoot": false,
  "Manifest": {
    "Author": "Test",
    "PowerShellHostVersion": "7.4",
    "GUID": "22222222-2222-2222-2222-222222222222",
    "Tags": [],
    "ProjectUri": ""
  },
  "Pester": {
    "TestResult": {
      "Enabled": true,
      "OutputFormat": "NUnitXml"
    },
    "Output": {
      "Verbosity": "Detailed"
    }
  }
}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Encoding utf8

        @'
function Invoke-TestCliVerbose {
    'ok'
}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'src/public/Invoke-TestCliVerbose.ps1') -Encoding utf8

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            Push-Location $projectRoot
            try {
                $buildOutput = & $installedPath build -Verbose 2>&1
                $buildText = @($buildOutput) -join [Environment]::NewLine
                $buildExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $buildExitCode | Should -Be 0
            $buildText | Should -Match 'VERBOSE: Running NovaModuleTools Version:'
            $buildText | Should -Match 'VERBOSE: Buidling module psm1 file'
            (Test-Path -LiteralPath (Join-Path $projectRoot 'dist/CliVerboseBuildProject/CliVerboseBuildProject.psm1')) | Should -BeTrue
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards -WhatIf from the standalone launcher without mutating build, bump, or publish state' {
        $targetDirectory = Join-Path $TestDrive 'whatif-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectRoot = Join-Path $TestDrive 'CliWhatIfProject'
        $projectJsonPath = Join-Path $projectRoot 'project.json'
        $builtModulePath = Join-Path $projectRoot 'dist/CliWhatIfProject/CliWhatIfProject.psm1'
        $testResultPath = Join-Path $projectRoot 'artifacts/TestResults.xml'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        Initialize-TestNovaCliProjectLayout -ProjectRoot $projectRoot
        Write-TestNovaCliProjectJson -ProjectRoot $projectRoot -ProjectName 'CliWhatIfProject' -ProjectGuid '33333333-3333-3333-3333-333333333333'
        Write-TestNovaCliPublicFunction -ProjectRoot $projectRoot -FunctionName 'Invoke-TestCliWhatIf'

        try {
            Initialize-TestNovaCliGitRepository -ProjectRoot $projectRoot -CommitMessage 'feat: add cli whatif coverage'

            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            $buildResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('build', '-WhatIf')
            $publishResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('publish', '--local', '-WhatIf')
            $bumpResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('bump', '-WhatIf')
            $versionAfterBump = (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).Version

            $buildResult.ExitCode | Should -Be 0
            $publishResult.ExitCode | Should -Be 0
            $bumpResult.ExitCode | Should -Be 0
            $buildResult.Text | Should -Match 'What if:'
            $publishResult.Text | Should -Match 'What if:'
            $publishResult.Text | Should -Not -Match 'Unknown argument:'
            $bumpResult.Text | Should -Match 'What if:'
            $bumpResult.Text | Should -Match '0\.0\.1\s+0\.1\.0\s+Minor\s+1'
            $bumpResult.Text | Should -Not -Match 'Version bumped to :'
            $versionAfterBump | Should -Be '0.0.1'
            (Test-Path -LiteralPath $builtModulePath) | Should -BeFalse
            (Test-Path -LiteralPath $testResultPath) | Should -BeFalse
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli rejects unsupported nova init invocations with clear migration guidance' -ForEach @(
        @{
            Name = 'WhatIf'
            TargetDirectory = 'init-whatif-bin'
            WorkspaceRoot = 'CliInitWhatIfRoot'
            Arguments = @('init', '-WhatIf')
            ExpectedPatterns = @('does not support -WhatIf')
            UnexpectedPatterns = @('Not a valid path')
        }
        @{
            Name = 'positional path'
            TargetDirectory = 'init-positional-bin'
            WorkspaceRoot = 'CliInitPositionalRoot'
            Arguments = @('init', 'some/path')
            ExpectedPatterns = @('positional paths are no longer accepted', 'nova init -Path some/path')
            UnexpectedPatterns = @()
        }
    ) {
        $targetDirectory = Join-Path $TestDrive $_.TargetDirectory
        $installedPath = Join-Path $targetDirectory 'nova'
        $workspaceRoot = Join-Path $TestDrive $_.WorkspaceRoot
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"
        New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null
            $initResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $workspaceRoot -Arguments $_.Arguments

            $initResult.ExitCode | Should -Not -Be 0
            foreach ($pattern in $_.ExpectedPatterns) {
                $initResult.Text | Should -Match $pattern
            }

            foreach ($pattern in $_.UnexpectedPatterns) {
                $initResult.Text | Should -Not -Match $pattern
            }
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Invoke-NovaCli version returns the project name and version' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'AzureDevOpsAgentInstaller'; Version = '1.2.3'}}

            Invoke-NovaCli version | Should -Be 'AzureDevOpsAgentInstaller 1.2.3'
            Assert-MockCalled Get-NovaProjectInfo -Times 1 -ParameterFilter {-not $Version}
        }
    }

    It 'Invoke-NovaCli --version formats stable and prerelease installed versions correctly' {
        InModuleScope $script:moduleName -Parameters @{ModuleName = $script:moduleName} {
            param($ModuleName)

            foreach ($testCase in @(
                @{InstalledVersion = '9.9.9'; Expected = "$ModuleName 9.9.9"},
                @{InstalledVersion = '9.9.9-preview'; Expected = "$ModuleName 9.9.9-preview"}
            )) {
                Mock Get-NovaCliInstalledVersion {$testCase.InstalledVersion}

                Invoke-NovaCli --version | Should -Be $testCase.Expected
                Assert-MockCalled Get-NovaCliInstalledVersion -Times 1 -Scope It
            }
        }
    }

    It 'Invoke-NovaCli --help returns CLI help text' {
        InModuleScope $script:moduleName {
            $result = Invoke-NovaCli --help

            $result | Should -Match 'usage: nova \[--version\] \[--help\] <command> \[<args>\]'
            $result | Should -Match 'init\s+Create a new Nova module scaffold'
            (($result -match 'notification\s+Show or change prerelease self-update eligibility') -and ($result -match 'nova notification -disable') -and ($result -match 'nova notification -enable')) | Should -BeTrue
            $result | Should -Match 'version\s+Show the current project version, or use -Installed for the locally installed project module version'
            $result | Should -Match 'nova version -Installed'
            $result | Should -Match '--version\s+Show the installed NovaModuleTools module name and version'
            $result | Should -Match 'merge\s+Build, test, and package the module as configured package artifact\(s\)'
            $result | Should -Match 'deploy\s+Upload generated package artifact\(s\) to a raw HTTP endpoint'
            $result | Should -Match 'publish\s+Build, test, and publish the module locally or to a repository'
        }
    }

    It 'Invoke-NovaCli <CommandName> --help returns routed command help' -ForEach @(
        @{CommandName = 'merge'; ExpectedPattern = 'Merge-NovaModule'},
        @{CommandName = 'deploy'; ExpectedPattern = 'Deploy-NovaPackage'},
        @{CommandName = 'init'; ExpectedPattern = 'Initialize-NovaModule'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $result = Invoke-NovaCli -Command $TestCase.CommandName -Arguments @('--help') | Out-String

            $result | Should -Match $TestCase.ExpectedPattern
        }
    }

    It 'Invoke-NovaCli merge routes to Merge-NovaModule' {
        InModuleScope $script:moduleName {
            Mock Merge-NovaModule {
                @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                )
            }

            $result = @(Invoke-NovaCli merge)

            $result.Type | Should -Be @('NuGet')
            $result.PackagePath | Should -Be @('/tmp/artifacts/packages/NovaModuleTools.1.2.3.nupkg')
        }
    }

    It 'Invoke-NovaCli <CommandName> forwards WhatIf to the routed command' -ForEach @(
        @{
            CommandName = 'merge'
            RoutedCommand = 'Merge-NovaModule'
            Arguments = @()
        }
        @{
            CommandName = 'deploy'
            RoutedCommand = 'Deploy-NovaPackage'
            Arguments = @('--url', 'https://packages.example/raw/')
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock $TestCase.RoutedCommand {
                [pscustomobject]@{WhatIfSeen = $WhatIfPreference}
            }

            $result = Invoke-NovaCli $TestCase.CommandName @($TestCase.Arguments) -WhatIf

            $result.WhatIfSeen | Should -BeTrue
        }
    }

    It 'Invoke-NovaCli deploy routes to Deploy-NovaPackage' {
        InModuleScope $script:moduleName {
            Mock Deploy-NovaPackage {
                [pscustomobject]@{
                    Repository = $Repository
                    Url = $Url
                    PackageType = $PackageType
                }
            }

            $result = Invoke-NovaCli deploy --repository LocalRaw --type zip

            $result.Repository | Should -Be 'LocalRaw'
            $result.PackageType | Should -Be @('zip')
        }
    }

    It 'Invoke-NovaCli deploy rejects the removed package subcommand token' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli deploy package --repository LocalRaw} | Should -Throw 'Unknown argument: package'
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

    It 'Invoke-NovaCli publish -local routes the local publish flow' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                [pscustomobject]@{Local = $Local}
            }

            $result = Invoke-NovaCli publish -local

            $result.Local | Should -BeTrue
        }
    }

    It 'Invoke-NovaCli forwards WhatIf to mutating routed commands' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                [pscustomobject]@{WhatIfSeen = $WhatIfPreference}
            }

            $result = Invoke-NovaCli publish --repository PSGallery --apikey key123 -WhatIf

            $result.WhatIfSeen | Should -BeTrue
        }
    }

    It 'Invoke-NovaCli init rejects -WhatIf with a clear error' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli init -WhatIf} | Should -Throw '*does not support -WhatIf*'
        }
    }

    It 'Invoke-NovaCli init rejects positional paths instead of treating them as -Path' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli init 'some/path'} | Should -Throw '*positional paths are no longer accepted*'
        }
    }

    It 'Invoke-NovaCli throws on unsupported argument' {
        InModuleScope $script:moduleName {
            {Invoke-NovaCli publish --bogus} | Should -Throw 'Unknown argument*'
        }
    }
}
