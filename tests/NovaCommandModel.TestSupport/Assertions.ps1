function Assert-TestStructuredError {
    [CmdletBinding()]
    param(
        [AllowNull()]$ThrownError,
        [Parameter(Mandatory)][pscustomobject]$ExpectedError
    )

    $ThrownError | Should -Not -BeNullOrEmpty
    $ThrownError.Exception.Message | Should -BeLike $ExpectedError.Message
    $ThrownError.FullyQualifiedErrorId | Should -Be $ExpectedError.ErrorId
    $ThrownError.CategoryInfo.Category | Should -Be $ExpectedError.Category
    if ($ExpectedError.PSObject.Properties.Name -contains 'TargetObject') {
        $ThrownError.TargetObject | Should -Be $ExpectedError.TargetObject
    }
}

function Assert-TestNovaCliConfirmDecisions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        foreach ($testCase in @(
            @{Key = 'Y'; Expected = $true},
            @{Key = 'A'; Expected = $true},
            @{Key = 'N'; Expected = $false},
            @{Key = 'L'; Expected = $false},
            @{Key = 'S'; Expected = $false},
            @{Key = 'y'; Expected = $true},
            @{Key = 'n'; Expected = $false}
        )) {
            $result = Get-NovaCliConfirmDecision -KeyChar ([char]$testCase.Key)
            $result | Should -Be $testCase.Expected
        }

        Get-NovaCliConfirmDecision -KeyChar ([char]'?') | Should -BeNullOrEmpty
    }
}

function Invoke-ReadNovaCliPromptKeyAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        Mock Read-NovaCliConsoleKeyChar {
            if ($TestCase.Throws) {
                throw 'console unavailable'
            }

            return $TestCase.ConsoleKeyChar
        }

        $result = Read-NovaCliPromptKey

        $result | Should -Be $TestCase.Expected
        Assert-MockCalled Read-NovaCliConsoleKeyChar -Times 1
    }
}

function Invoke-GetNovaCliCommandPromptKeyAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        $originalResponse = $env:NOVA_CLI_CONFIRM_RESPONSE
        try {
            $env:NOVA_CLI_CONFIRM_RESPONSE = $TestCase.EnvironmentResponse
            Mock Write-Host {}
            Mock Read-NovaCliPromptKey {[char]'n'}

            $result = Get-NovaCliCommandPromptKey -Message "Continue with 'nova build'?"

            $result | Should -Be $TestCase.Expected
            Assert-MockCalled Read-NovaCliPromptKey -Times $TestCase.PromptReadCount
        }
        finally {
            $env:NOVA_CLI_CONFIRM_RESPONSE = $originalResponse
        }
    }
}

function Invoke-GetNovaCliCommandCancellationInfoAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        $result = Get-NovaCliCommandCancellationInfo -Command 'build' -KeyChar ([char]$TestCase.Key)

        $result.Command | Should -Be 'build'
        $result.Message | Should -Be $TestCase.ExpectedMessage
        $result.ErrorId | Should -Be $TestCase.ExpectedErrorId
    }
}

function Invoke-UpdateNovaModuleVersionDefaultPathAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        Mock Get-Location {[pscustomobject]@{Path = '/tmp/current-project'}}
        Mock Resolve-Path {[pscustomobject]@{Path = '/tmp/current-project'}} -ParameterFilter {$LiteralPath -eq '/tmp/current-project'}
        Mock Get-NovaVersionUpdateWorkflowContext {
            [pscustomobject]@{
                Target = 'project.json'
                Action = 'Update module version using Minor release label'
            }
        }
        Mock Invoke-NovaVersionUpdateWorkflow {
            [pscustomobject]@{NewVersion = '1.1.0'; Applied = $true}
        }
        Mock Write-Host {}

        $result = Update-NovaModuleVersion -Confirm:$false

        $result.NewVersion | Should -Be '1.1.0'
        Assert-MockCalled Get-NovaVersionUpdateWorkflowContext -Times 1 -ParameterFilter {
            $ProjectRoot -eq '/tmp/current-project' -and -not $PreviewRelease
        }
    }
}

function Invoke-TestPublishWorkflowCiRestoreAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$AssertionCase
    )

    InModuleScope $AssertionCase.ModuleName -Parameters @{TestCase = $AssertionCase.TestCase} {
        param($TestCase)

        $script:steps = @()

        Mock Invoke-NovaBuild {$script:steps += 'build'}
        Mock Test-NovaBuild {$script:steps += 'test'}
        Mock Get-Module {@()}
        Mock Test-Path {$true} -ParameterFilter {$LiteralPath -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'}
        Mock Import-Module {
            $script:steps += 'ci'
            [pscustomobject]@{Path = $Name}
        } -ParameterFilter {$Name -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1' -and $Force -and $Global -and $PassThru}

        $localPublishActivation = $null
        if ($TestCase.UseLocalPublishActivation) {
            $localPublishActivation = [pscustomobject]@{
                ManifestPath = '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
                ImportAction = {param($ProjectName, $ManifestPath) $script:steps += 'import'}
            }
        }

        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                OutputModuleDir = '/tmp/dist/NovaModuleTools'
            }
            WorkflowParams = @{}
            ContinuousIntegrationRequested = $true
            PublishInvocation = [pscustomobject]@{
                Parameters = @{
                    ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                }
                Action = {$script:steps += 'publish'}
            }
            PublishParams = @{}
            LocalPublishActivation = $localPublishActivation
        }

        Invoke-NovaPublishWorkflow -WorkflowContext $workflowContext -ShouldRun | Out-Null

        $script:steps -join ',' | Should -Be $TestCase.ExpectedSteps
        Assert-MockCalled Import-Module -Times 1 -ParameterFilter {$Name -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1' -and $Force -and $Global -and $PassThru}
    }
}

function Invoke-ConfirmNovaCliCommandActionEnterAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        Mock Get-NovaCliCommandPromptKey {[char]13}
        Mock Write-Host {}
        Mock Stop-NovaOperation {}

        Confirm-NovaCliCommandAction -Command 'build'

        Assert-MockCalled Get-NovaCliCommandPromptKey -Times 1 -ParameterFilter {$Message -eq "Continue with 'nova build'?"}
        Assert-MockCalled Stop-NovaOperation -Times 0
    }
}

function Invoke-ConfirmNovaCliCommandActionRetryAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        $script:promptKeyList = @([char]'?', [char]'Y')
        $script:promptKeyIndex = 0
        Mock Get-NovaCliCommandPromptKey {
            $result = $script:promptKeyList[$script:promptKeyIndex]
            $script:promptKeyIndex += 1
            return $result
        }
        Mock Write-Host {}
        Mock Stop-NovaOperation {}

        Confirm-NovaCliCommandAction -Command 'build'

        Assert-MockCalled Get-NovaCliCommandPromptKey -Times 2 -ParameterFilter {$Message -eq "Continue with 'nova build'?"}
        Assert-MockCalled Write-Host -Times 1 -ParameterFilter {$Object -eq ([char]'Y')}
        Assert-MockCalled Stop-NovaOperation -Times 0
    }
}

function Invoke-ConfirmNovaCliCommandActionCancellationAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        Mock Get-NovaCliCommandPromptKey {[char]$TestCase.Key}
        Mock Write-Host {}
        Mock Stop-NovaOperation {}

        Confirm-NovaCliCommandAction -Command 'build'

        Assert-MockCalled Write-Host -Times 1 -ParameterFilter {$Object -eq ([char]$TestCase.Key)}
        Assert-MockCalled Stop-NovaOperation -Times 1 -ParameterFilter {
            $Message -eq $TestCase.ExpectedMessage -and
                    $ErrorId -eq $TestCase.ExpectedErrorId -and
                    $Category -eq 'OperationStopped' -and
                    $TargetObject -eq 'build'
        }
    }
}

function Get-TestInstalledNovaCliSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstalledPath,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $snapshot = [ordered]@{
        HelpText = @((& $InstalledPath --help 2>&1)) -join [Environment]::NewLine
        HelpExitCode = $LASTEXITCODE
        CommandHelpText = @((& $InstalledPath build --help 2>&1)) -join [Environment]::NewLine
        CommandHelpExitCode = $LASTEXITCODE
        LongHelpText = @((& $InstalledPath -h build 2>&1)) -join [Environment]::NewLine
        LongHelpExitCode = $LASTEXITCODE
        VersionText = @((& $InstalledPath --version 2>&1)) -join [Environment]::NewLine
        VersionExitCode = $LASTEXITCODE
        ShortVersionText = @((& $InstalledPath -v 2>&1)) -join [Environment]::NewLine
        ShortVersionExitCode = $LASTEXITCODE
    }

    Push-Location $ProjectRoot
    try {
        $snapshot.ProjectVersionText = @((& $InstalledPath version 2>&1)) -join [Environment]::NewLine
        $snapshot.ProjectVersionExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    return [pscustomobject]$snapshot
}

function Assert-TestInstalledNovaCliSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Snapshot,
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][string]$InstalledModuleVersion,
        [Parameter(Mandatory)][string]$ExpectedProjectVersionText
    )

    $Snapshot.HelpExitCode | Should -Be 0
    $Snapshot.CommandHelpExitCode | Should -Be 0
    $Snapshot.LongHelpExitCode | Should -Be 0
    $Snapshot.VersionExitCode | Should -Be 0
    $Snapshot.ShortVersionExitCode | Should -Be 0
    $Snapshot.ProjectVersionExitCode | Should -Be 0
    $Snapshot.HelpText | Should -Match 'usage: nova \[--version\|-v\] \[--help\|-h\] <command> \[<args>\]'
    $Snapshot.HelpText | Should -Match 'Use ''nova <command> --help'' or ''nova <command> -h'' for short command help\.'
    $Snapshot.HelpText | Should -Match 'Use ''nova --help <command>'' or ''nova -h <command>'' for long command help\.'
    $Snapshot.HelpText | Should -Match "Root '-v' means '--version', while command-level '-v' means '--verbose'"
    ($Snapshot.HelpText -match 'notification\s+Show or change prerelease self-update eligibility') | Should -BeTrue
    $Snapshot.HelpText | Should -Match 'version\s+Show the current project version, or use --installed/-i for the locally installed project module version'
    $Snapshot.HelpText | Should -Match 'package\s+Build, test, and package the module as configured package artifact\(s\)'
    $Snapshot.HelpText | Should -Match 'nova deploy --repository LocalNexus'
    $Snapshot.HelpText | Should -Not -Match 'nova build -Verbose'
    $Snapshot.HelpText | Should -Not -Match 'nova deploy -repository'
    $Snapshot.HelpText | Should -Not -Match 'nova deploy package'
    $Snapshot.CommandHelpText | Should -Match '^usage: nova build \[<options>\]'
    $Snapshot.CommandHelpText | Should -Match 'Options:'
    $Snapshot.CommandHelpText | Should -Match '-v, --verbose'
    $Snapshot.LongHelpText | Should -Match '^NAME'
    $Snapshot.LongHelpText | Should -Match 'SYNOPSIS'
    $Snapshot.LongHelpText | Should -Match 'DESCRIPTION'
    $Snapshot.LongHelpText | Should -Match 'OPTIONS'
    $Snapshot.LongHelpText | Should -Match 'EXAMPLES'
    $Snapshot.LongHelpText | Should -Not -Match '(?<!-)-Verbose\b'
    $Snapshot.VersionText | Should -Be "$ModuleName $InstalledModuleVersion"
    $Snapshot.ShortVersionText | Should -Be "$ModuleName $InstalledModuleVersion"
    $Snapshot.ProjectVersionText | Should -Be $ExpectedProjectVersionText
}

function Assert-TestNovaCliPublishConfirmationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [Parameter(Mandatory)][string]$PublishManifestPath,
        [Parameter(Mandatory)]$TestCase
    )

    if ($TestCase.ExpectSuccess) {
        $Result.ExitCode | Should -Be 0
        (Test-Path -LiteralPath $PublishManifestPath) | Should -BeTrue
        $Result.Text | Should -Not -Match 'Suspend is not supported in nova CLI mode'
        $Result.Text | Should -Not -Match 'Operation cancelled\.'
        return
    }

    $Result.ExitCode | Should -Not -Be 0
    (Test-Path -LiteralPath $PublishManifestPath) | Should -BeFalse

    if ($TestCase.ExpectSuspendMessage) {
        $Result.Text | Should -Match 'Suspend is not supported in nova CLI mode\. Operation cancelled\.'
        return
    }

    $Result.Text | Should -Match 'Operation cancelled\.'
}

