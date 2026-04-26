$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
. $script:testSupportPath

Publish-TestSupportFunctions -FunctionNameList @(
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
    'Get-TestInstalledNovaCliSnapshot'
    'Assert-TestInstalledNovaCliSnapshot'
)

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
    Publish-TestSupportFunctions -FunctionNameList @(
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
        'Get-TestInstalledNovaCliSnapshot'
        'Assert-TestInstalledNovaCliSnapshot'
    )
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
            $snapshot = Get-TestInstalledNovaCliSnapshot -InstalledPath $installedPath -ProjectRoot $script:projectInfo.ProjectRoot

            $result.CommandName | Should -Be 'nova'
            $result.InstalledPath | Should -Be $installedPath
            $result.DestinationDirectory | Should -Be $targetDirectory
            (Test-Path -LiteralPath $installedPath) | Should -BeTrue
            Assert-TestInstalledNovaCliSnapshot -Snapshot $snapshot -ModuleName $script:moduleName -InstalledModuleVersion $installedModuleVersion -ExpectedProjectVersionText $expectedProjectVersionText
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards --verbose and -v from the standalone launcher to build output' {
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
                $longBuildOutput = & $installedPath build --verbose 2>&1
                $longBuildText = @($longBuildOutput) -join [Environment]::NewLine
                $longBuildExitCode = $LASTEXITCODE
                $shortBuildOutput = & $installedPath build -v 2>&1
                $shortBuildText = @($shortBuildOutput) -join [Environment]::NewLine
                $shortBuildExitCode = $LASTEXITCODE
            }
            finally {
                Pop-Location
            }

            $longBuildExitCode | Should -Be 0
            $shortBuildExitCode | Should -Be 0
            $longBuildText | Should -Match 'VERBOSE: Running NovaModuleTools Version:'
            $longBuildText | Should -Match 'VERBOSE: Buidling module psm1 file'
            $shortBuildText | Should -Match 'VERBOSE: Running NovaModuleTools Version:'
            $shortBuildText | Should -Match 'VERBOSE: Buidling module psm1 file'
            (Test-Path -LiteralPath (Join-Path $projectRoot 'dist/CliVerboseBuildProject/CliVerboseBuildProject.psm1')) | Should -BeTrue
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards --what-if and -w from the standalone launcher without mutating build, test, bump, or publish state' {
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

            @'
Describe 'CLI WhatIf test project' {
    It 'passes' {
        $true | Should -BeTrue
    }
}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'tests/CliWhatIf.Tests.ps1') -Encoding utf8

            $buildResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('build', '--what-if')
            $shortTestResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('test', '-w')
            $longTestResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('test', '--what-if')
            $publishResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('publish', '--local', '-w')
            $bumpResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('bump', '-w')
            $previewBumpResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('bump', '--preview', '--what-if')
            $versionAfterBump = (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).Version

            $buildResult.ExitCode | Should -Be 0
            $shortTestResult.ExitCode | Should -Be 0
            $longTestResult.ExitCode | Should -Be 0
            $publishResult.ExitCode | Should -Be 0
            $bumpResult.ExitCode | Should -Be 0
            $previewBumpResult.ExitCode | Should -Be 0
            $buildResult.Text | Should -Match 'What if:'
            $shortTestResult.Text | Should -Match 'What if:'
            $longTestResult.Text | Should -Match 'What if:'
            $publishResult.Text | Should -Match 'What if:'
            $publishResult.Text | Should -Not -Match 'Unknown argument:'
            $bumpResult.Text | Should -Match 'What if:'
            $bumpResult.Text | Should -Match '0\.0\.1\s+0\.1\.0\s+Minor\s+1'
            $previewBumpResult.Text | Should -Match 'What if:'
            $previewBumpResult.Text | Should -Match '0\.0\.1\s+0\.1\.0-preview\s+Minor\s+1'
            $bumpResult.Text | Should -Not -Match 'Version bumped to :'
            $previewBumpResult.Text | Should -Not -Match 'Unknown argument:'
            $previewBumpResult.Text | Should -Not -Match 'Version bumped to :'
            $versionAfterBump | Should -Be '0.0.1'
            (Test-Path -LiteralPath $builtModulePath) | Should -BeFalse
            (Test-Path -LiteralPath $testResultPath) | Should -BeFalse
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli rejects deprecated nova test what-if spellings with migration guidance' -ForEach @(
        @{Arguments = @('test', '--whatif'); ExpectedPattern = "Unsupported CLI option syntax: --whatif. Use '--what-if' or '-w' instead."}
        @{Arguments = @('test', '-whatif'); ExpectedPattern = "Unsupported CLI option syntax: -whatif. Use '--what-if' or '-w' instead."}
    ) {
        $testCase = $_
        $targetDirectory = Join-Path $TestDrive "deprecated-whatif-bin-$($testCase.Arguments[1].Replace('-', '') )"
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectRoot = Join-Path $TestDrive "CliDeprecatedWhatIf$($testCase.Arguments[1].Replace('-', '') )"
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"
        Initialize-TestNovaCliProjectLayout -ProjectRoot $projectRoot
        Write-TestNovaCliProjectJson -ProjectRoot $projectRoot -ProjectName ([System.IO.Path]::GetFileName($projectRoot)) -ProjectGuid ([guid]::NewGuid().Guid)
        Write-TestNovaCliPublicFunction -ProjectRoot $projectRoot -FunctionName 'Invoke-TestCliDeprecatedWhatIf'

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            $result = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments $testCase.Arguments
            $expectedPattern = [regex]::Escape($testCase.ExpectedPattern)

            $result.ExitCode | Should -Not -Be 0
            $result.Text | Should -Match $expectedPattern
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli handles publish CLI confirmation safely for <Option> with <Response>' -ForEach @(
        @{Option = '--confirm'; Response = 'Y'; ExpectSuccess = $true; ExpectSuspendMessage = $false}
        @{Option = '--confirm'; Response = 'N'; ExpectSuccess = $false; ExpectSuspendMessage = $false}
        @{Option = '--confirm'; Response = 'S'; ExpectSuccess = $false; ExpectSuspendMessage = $true}
        @{Option = '-c'; Response = 'Y'; ExpectSuccess = $true; ExpectSuspendMessage = $false}
        @{Option = '-c'; Response = 'N'; ExpectSuccess = $false; ExpectSuspendMessage = $false}
        @{Option = '-c'; Response = 'S'; ExpectSuccess = $false; ExpectSuspendMessage = $true}
    ) {
        $testCase = $_
        $targetDirectory = Join-Path $TestDrive "confirm-bin-$($testCase.Option.Replace('-', '') )-$( $testCase.Response )"
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectName = "CliPublishConfirm$($testCase.Option.Replace('-', '') )$( $testCase.Response )"
        $projectRoot = Join-Path $TestDrive $projectName
        $publishDir = Join-Path $TestDrive "publish-output-$($testCase.Option.Replace('-', '') )-$( $testCase.Response )"
        $publishManifestPath = Join-Path $publishDir "$projectName/$projectName.psd1"
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        Initialize-TestNovaCliProjectLayout -ProjectRoot $projectRoot
        Write-TestNovaCliProjectJson -ProjectRoot $projectRoot -ProjectName $projectName -ProjectGuid ([guid]::NewGuid().Guid)
        Write-TestNovaCliPublicFunction -ProjectRoot $projectRoot -FunctionName "Invoke-$projectName"
        @'
Describe '$projectName tests' {
    It 'passes' {
        $true | Should -BeTrue
    }
}
'@ | Set-Content -LiteralPath (Join-Path $projectRoot 'tests/PublishConfirm.Tests.ps1') -Encoding utf8

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            $result = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('publish', '--local', '--path', $publishDir, $testCase.Option) -EnvironmentVariables @{NOVA_CLI_CONFIRM_RESPONSE = $testCase.Response}
            Assert-TestNovaCliPublishConfirmationResult -Result $result -PublishManifestPath $publishManifestPath -TestCase $testCase
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Install-NovaCli forwards --preview so prerelease bumps keep the same semantic core and increment the current prerelease label' {
        $targetDirectory = Join-Path $TestDrive 'preview-bump-bin'
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectRoot = Join-Path $TestDrive 'CliPreviewBumpProject'
        $projectJsonPath = Join-Path $projectRoot 'project.json'
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        Initialize-TestNovaCliProjectLayout -ProjectRoot $projectRoot
        Write-TestNovaCliProjectJson -ProjectRoot $projectRoot -ProjectName 'CliPreviewBumpProject' -ProjectGuid '44444444-4444-4444-4444-444444444444'
        Write-TestNovaCliPublicFunction -ProjectRoot $projectRoot -FunctionName 'Invoke-TestCliPreviewBump'

        $projectData = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json
        $projectData.Version = '0.0.1-rc1'
        $projectData | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        try {
            Initialize-TestNovaCliGitRepository -ProjectRoot $projectRoot -CommitMessage 'feat!: add prerelease cli bump coverage'

            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            $previewBumpResult = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('bump', '--preview', '--what-if')
            $versionAfterBump = (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).Version

            $previewBumpResult.ExitCode | Should -Be 0
            $previewBumpResult.Text | Should -Match 'What if:'
            $previewBumpResult.Text | Should -Match '0\.0\.1-rc1\s+0\.0\.1-rc2\s+Major\s+1'
            $previewBumpResult.Text | Should -Not -Match 'Unknown argument:'
            $previewBumpResult.Text | Should -Not -Match 'Version bumped to :'
            $versionAfterBump | Should -Be '0.0.1-rc1'
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
            Arguments = @('init', '--what-if')
            ExpectedPatterns = @('does not support ''--what-if''/''-w''')
            UnexpectedPatterns = @('Not a valid path')
        }
        @{
            Name = 'positional path'
            TargetDirectory = 'init-positional-bin'
            WorkspaceRoot = 'CliInitPositionalRoot'
            Arguments = @('init', 'some/path')
            ExpectedPatterns = @('positional paths are no longer accepted', 'nova init --path some/path')
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

    It 'Install-NovaCli rebuilds before testing when nova test uses <Option>' -ForEach @(
        @{Option = '--build'}
        @{Option = '-b'}
    ) {
        $option = $_.Option
        $targetDirectory = Join-Path $TestDrive "test-build-bin-$($option.Replace('-', '') )"
        $installedPath = Join-Path $targetDirectory 'nova'
        $projectName = "CliTestBuild$($option.Replace('-', '') )"
        $projectRoot = Join-Path $TestDrive $projectName
        $topMarker = Join-Path $projectRoot 'top-level-ran.txt'
        $builtModulePath = Join-Path $projectRoot "dist/$projectName/$projectName.psm1"
        $originalModulePath = $env:PSModulePath
        $modulePathSeparator = [string][System.IO.Path]::PathSeparator
        $distParent = Split-Path -Parent $script:distModuleDir

        $env:PSModulePath = "$distParent$modulePathSeparator$originalModulePath"

        Initialize-TestNovaCliProjectLayout -ProjectRoot $projectRoot
        Write-TestNovaCliProjectJson -ProjectRoot $projectRoot -ProjectName $projectName -ProjectGuid ([guid]::NewGuid().Guid)
        Write-TestNovaCliPublicFunction -ProjectRoot $projectRoot -FunctionName "Invoke-$projectName"
        @"
Describe '$projectName tests' {
    It 'imports the built module and writes a marker' {
        Import-Module '$builtModulePath' -Force
        Get-Module -Name '$projectName' | Should -Not -BeNullOrEmpty
        Set-Content -LiteralPath '$topMarker' -Value 'TopLevel' -Encoding utf8 -NoNewline
    }
}
"@ | Set-Content -LiteralPath (Join-Path $projectRoot 'tests/TestBuildFlag.Tests.ps1') -Encoding utf8

        try {
            Install-NovaCli -DestinationDirectory $targetDirectory -Force | Out-Null

            (Test-Path -LiteralPath $builtModulePath) | Should -BeFalse
            $result = Invoke-TestInstalledNovaCommand -InstalledPath $installedPath -WorkingDirectory $projectRoot -Arguments @('test', $option)

            $result.ExitCode | Should -Be 0 -Because $result.Text
            (Test-Path -LiteralPath $builtModulePath) | Should -BeTrue
            (Test-Path -LiteralPath $topMarker) | Should -BeTrue
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

    It 'Invoke-NovaCli --version and -v format stable and prerelease installed versions correctly' {
        InModuleScope $script:moduleName -Parameters @{ModuleName = $script:moduleName} {
            param($ModuleName)

            foreach ($testCase in @(
                @{InstalledVersion = '9.9.9'; Expected = "$ModuleName 9.9.9"},
                @{InstalledVersion = '9.9.9-preview'; Expected = "$ModuleName 9.9.9-preview"}
            )) {
                Mock Get-NovaCliInstalledVersion {$testCase.InstalledVersion}

                Invoke-NovaCli --version | Should -Be $testCase.Expected
                Invoke-NovaCli -Command '-v' | Should -Be $testCase.Expected
                Assert-MockCalled Get-NovaCliInstalledVersion -Times 2 -Scope It
            }
        }
    }

    It 'Invoke-NovaCli --help returns CLI help text' {
        InModuleScope $script:moduleName {
            $result = Invoke-NovaCli --help

            $result | Should -Match 'usage: nova \[--version\|-v\] \[--help\|-h\] <command> \[<args>\]'
            $result | Should -Match 'init\s+Create a new Nova module scaffold'
            (($result -match 'notification\s+Show or change prerelease self-update eligibility') -and ($result -match 'nova notification --disable') -and ($result -match 'nova notification --enable')) | Should -BeTrue
            $result | Should -Match 'version\s+Show the current project version, or use --installed/-i for the locally installed project module version'
            $result | Should -Match 'nova version --installed'
            $result | Should -Match '--version, -v\s+Show the installed NovaModuleTools module name and version'
            $result | Should -Match 'nova --help <command>'
            $result | Should -Match "Root '-v' means '--version', while command-level '-v' means '--verbose'"
            $result | Should -Match 'package\s+Build, test, and package the module as configured package artifact\(s\)'
            $result | Should -Match 'deploy\s+Upload generated package artifact\(s\) to a raw HTTP endpoint'
            $result | Should -Match 'publish\s+Build, test, and publish the module locally or to a repository'
            $result | Should -Not -Match 'nova build -Verbose'
            $result | Should -Not -Match 'nova publish -repository PSGallery -apikey'
        }
    }

    It 'Invoke-NovaCli <CommandName> --help returns CLI-native short help' -ForEach @(
        @{CommandName = 'init'; Usage = 'usage: nova init [<options>]'; ExpectedPattern = '-p, --path <path>'},
        @{CommandName = 'info'; Usage = 'usage: nova info'; ExpectedPattern = '\(none\)'},
        @{CommandName = 'version'; Usage = 'usage: nova version [<options>]'; ExpectedPattern = '-i, --installed'},
        @{CommandName = 'build'; Usage = 'usage: nova build [<options>]'; ExpectedPattern = '-v, --verbose'},
        @{CommandName = 'test'; Usage = 'usage: nova test [<options>]'; ExpectedPattern = '-b, --build'},
        @{CommandName = 'package'; Usage = 'usage: nova package [<options>]'; ExpectedPattern = '-c, --confirm'},
        @{CommandName = 'deploy'; Usage = 'usage: nova deploy [<options>]'; ExpectedPattern = '-r, --repository <name>'},
        @{CommandName = 'bump'; Usage = 'usage: nova bump [<options>]'; ExpectedPattern = '-p, --preview'},
        @{CommandName = 'update'; Usage = 'usage: nova update [<options>]'; ExpectedPattern = '-w, --what-if'},
        @{CommandName = 'notification'; Usage = 'usage: nova notification [<options>]'; ExpectedPattern = '-e, --enable'},
        @{CommandName = 'publish'; Usage = 'usage: nova publish [<options>]'; ExpectedPattern = '-l, --local'},
        @{CommandName = 'release'; Usage = 'usage: nova release [<options>]'; ExpectedPattern = '-r, --repository <name>'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $result = Invoke-NovaCli -Command $TestCase.CommandName -Arguments @('--help')

            $result | Should -Match ([regex]::Escape($TestCase.Usage))
            $result | Should -Match 'Options:'
            $result | Should -Match $TestCase.ExpectedPattern
            $result | Should -Not -Match '(?<!-)-Repository\b'
            $result | Should -Not -Match 'PS>'
        }
    }

    It 'Invoke-NovaCli root help syntax returns CLI-native long help for <CommandName>' -ForEach @(
        @{CommandName = 'init'}
        @{CommandName = 'info'}
        @{CommandName = 'version'}
        @{CommandName = 'build'}
        @{CommandName = 'test'}
        @{CommandName = 'package'}
        @{CommandName = 'deploy'}
        @{CommandName = 'bump'}
        @{CommandName = 'update'}
        @{CommandName = 'notification'}
        @{CommandName = 'publish'}
        @{CommandName = 'release'}
    ) {
        InModuleScope $script:moduleName -Parameters @{CommandName = $_.CommandName} {
            param($CommandName)

            $result = Invoke-NovaCli -Command '--help' -Arguments @($CommandName)

            $result | Should -Match '^NAME'
            $result | Should -Match "nova $CommandName -"
            $result | Should -Match 'SYNOPSIS'
            $result | Should -Match 'DESCRIPTION'
            $result | Should -Match 'OPTIONS'
            $result | Should -Match 'EXAMPLES'
            $result | Should -Not -Match '(?<!-)-Repository\b'
            $result | Should -Not -Match 'PS>'
        }
    }

    It 'Invoke-NovaCli CLI help never delegates to PowerShell Get-Help' {
        InModuleScope $script:moduleName {
            Mock Get-Help {throw 'CLI help should not call Get-Help'}

            {Invoke-NovaCli build --help} | Should -Not -Throw
            {Invoke-NovaCli -Command '--help' -Arguments @('build')} | Should -Not -Throw

            Assert-MockCalled Get-Help -Times 0
        }
    }

    It 'Invoke-NovaCli package routes to New-NovaModulePackage' {
        InModuleScope $script:moduleName {
            Mock New-NovaModulePackage {
                @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                )
            }

            $result = @(Invoke-NovaCli package)

            $result.Type | Should -Be @('NuGet')
            $result.PackagePath | Should -Be @('/tmp/artifacts/packages/NovaModuleTools.1.2.3.nupkg')
        }
    }

    It 'Invoke-NovaCli <CommandName> forwards WhatIf to the routed command' -ForEach @(
        @{
            CommandName = 'package'
            RoutedCommand = 'New-NovaModulePackage'
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

    It 'Invoke-NovaCli maps routed GNU-style common options while keeping CLI confirm out of the underlying PowerShell command parameters' {
        InModuleScope $script:moduleName {
            Mock Confirm-NovaCliCommandAction {}
            Mock Invoke-NovaBuild {
                param([switch]$Verbose, [switch]$WhatIf, [bool]$Confirm)

                [pscustomobject]@{
                    Verbose = $Verbose.IsPresent
                    WhatIf = $WhatIf.IsPresent
                    Confirm = $Confirm
                }
            }

            foreach ($arguments in @(@('--verbose', '--confirm'), @('-v', '-c'))) {
                $result = Invoke-NovaCli build @arguments

                $result.Verbose | Should -BeTrue
                $result.WhatIf | Should -BeFalse
                $result.Confirm | Should -BeFalse
            }

            Assert-MockCalled Confirm-NovaCliCommandAction -Times 2 -ParameterFilter {$Command -eq 'build'}
        }
    }

    It 'Invoke-NovaCli surfaces structured CLI errors for <Name>' -ForEach @(
        @{
            Name = 'the removed deploy package subcommand token'
            Action = {
                Invoke-NovaCli deploy package --repository LocalRaw
            }
            ExpectedError = [pscustomobject]@{
                Message = 'Unknown argument: package'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = 'package'
            }
        }
        @{
            Name = 'an unsupported publish argument'
            Action = {
                Invoke-NovaCli publish --bogus
            }
            ExpectedError = [pscustomobject]@{
                Message = 'Unknown argument: --bogus'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--bogus'
            }
        }
        @{
            Name = 'unsupported init WhatIf usage'
            Action = {
                Invoke-NovaCli init --what-if
            }
            ExpectedError = [pscustomobject]@{
                Message = "The 'nova init' CLI command does not support '--what-if'/'-w'. Run 'nova init' or 'nova init --path <path>' without preview mode."
                ErrorId = 'Nova.Validation.UnsupportedInitCliWhatIf'
                Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                TargetObject = 'WhatIf'
            }
        }
        @{
            Name = 'unsupported positional init path usage'
            Action = {
                Invoke-NovaCli init 'some/path'
            }
            ExpectedError = [pscustomobject]@{
                Message = "Unsupported 'nova init' usage: positional paths are no longer accepted. Use 'nova init --path some/path' or 'nova init -p some/path' instead."
                ErrorId = 'Nova.Validation.UnsupportedInitCliUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = 'some/path'
            }
        }
        @{
            Name = 'unsupported PowerShell-style CLI option syntax'
            Action = {
                Invoke-NovaCli -Command build -Arguments @('-WhatIf')
            }
            ExpectedError = [pscustomobject]@{
                Message = "Unsupported CLI option syntax: -WhatIf. Use '--what-if' or '-w' instead."
                ErrorId = 'Nova.Validation.UnsupportedCliOptionSyntax'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '-WhatIf'
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $thrown = $null
            try {
                & $TestCase.Action
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be $TestCase.ExpectedError.Message
            $thrown.FullyQualifiedErrorId | Should -Be $TestCase.ExpectedError.ErrorId
            $thrown.CategoryInfo.Category | Should -Be $TestCase.ExpectedError.Category
            $thrown.TargetObject | Should -Be $TestCase.ExpectedError.TargetObject
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

            $result = Invoke-NovaCli publish --repository PSGallery --api-key key123

            $result.Repository | Should -Be 'PSGallery'
            $result.ApiKey | Should -Be 'key123'
        }
    }

    It 'Invoke-NovaCli publish uses the CLI confirmation wrapper for --confirm and -c without forwarding raw Confirm' {
        InModuleScope $script:moduleName {
            Mock Confirm-NovaCliCommandAction {}
            Mock Publish-NovaModule {
                param([bool]$Confirm = $false)

                [pscustomobject]@{
                    Repository = $Repository
                    ApiKey = $ApiKey
                    Confirm = $Confirm
                }
            }

            foreach ($arguments in @(
                @('publish', '--repository', 'PSGallery', '--api-key', 'key123', '--confirm'),
                @('publish', '--repository', 'PSGallery', '--api-key', 'key123', '-c')
            )) {
                $result = Invoke-NovaCli @arguments

                $result.Repository | Should -Be 'PSGallery'
                $result.ApiKey | Should -Be 'key123'
                $result.Confirm | Should -BeFalse
            }

            Assert-MockCalled Confirm-NovaCliCommandAction -Times 2 -ParameterFilter {$Command -eq 'publish'}
        }
    }

    It 'Invoke-NovaCli publish --local routes the local publish flow' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                [pscustomobject]@{Local = $Local}
            }

            $result = Invoke-NovaCli publish --local

            $result.Local | Should -BeTrue
        }
    }

    It 'Invoke-NovaCli forwards WhatIf to mutating routed commands' {
        InModuleScope $script:moduleName {
            Mock Publish-NovaModule {
                [pscustomobject]@{WhatIfSeen = $WhatIfPreference}
            }

            $result = Invoke-NovaCli publish --repository PSGallery --api-key key123 -WhatIf

            $result.WhatIfSeen | Should -BeTrue
        }
    }

}
