$script:coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
$global:cliHelperCoverageSupportFunctionNameList = @(
    'Assert-TestStructuredCliError'
)
. $script:coverageGapsCliTestSupportPath

foreach ($functionName in $global:cliHelperCoverageSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"
    $coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $coverageGapsCliTestSupportPath
    foreach ($functionName in $global:cliHelperCoverageSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Targeted coverage for smaller CLI helper internals' {
    It 'CLI help helpers expose the usage text, unsupported usage errors, empty examples, and direct option accumulation' {
        InModuleScope $script:moduleName {
            Get-NovaCliHelpUsageText | Should -Be "Use 'nova --help', 'nova -h', 'nova --help <command>', 'nova -h <command>', or 'nova <command> --help'/'nova <command> -h'."
            Get-NovaCliExampleText -Examples @() | Should -Be '  (none)'

            $options = @{}
            Add-NovaCliOptionValue -Options $options -Name 'path' -Value '/tmp/one'
            Add-NovaCliOptionValue -Options $options -Name 'path' -Value '/tmp/two'

            $options.path | Should -Be @('/tmp/one', '/tmp/two')

            $directHelpUsageError = $null
            try {
                Assert-NovaCliHelpUsageSupported -Tokens @('--help', 'build')
            }
            catch {
                $directHelpUsageError = $_
            }

            Assert-TestStructuredCliError -ThrownError $directHelpUsageError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported help usage. Use 'nova --help', 'nova -h', 'nova --help <command>', 'nova -h <command>', or 'nova <command> --help'/'nova <command> -h'."
                ErrorId = 'Nova.Validation.UnsupportedCliHelpUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--help build'
            })

            $rootHelpUsageError = $null
            try {
                Get-NovaCliHelpRequest -Command '--help' -Arguments @('--help')
            }
            catch {
                $rootHelpUsageError = $_
            }

            Assert-TestStructuredCliError -ThrownError $rootHelpUsageError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported help usage. Use 'nova --help', 'nova -h', 'nova --help <command>', 'nova -h <command>', or 'nova <command> --help'/'nova <command> -h'."
                ErrorId = 'Nova.Validation.UnsupportedCliHelpUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--help --help'
            })

            $subcommandHelpUsageError = $null
            try {
                Get-NovaCliHelpRequest -Command 'build' -Arguments @('--help', 'extra')
            }
            catch {
                $subcommandHelpUsageError = $_
            }

            Assert-TestStructuredCliError -ThrownError $subcommandHelpUsageError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported help usage. Use 'nova --help', 'nova -h', 'nova --help <command>', 'nova -h <command>', or 'nova <command> --help'/'nova <command> -h'."
                ErrorId = 'Nova.Validation.UnsupportedCliHelpUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = 'build --help extra'
            })
        }
    }

    It 'Get-NovaCliForwardingParameterSet includes verbose and should-process options directly when requested' {
        InModuleScope $script:moduleName {
            $previousWhatIfPreference = $WhatIfPreference
            try {
                $WhatIfPreference = $true
                $result = Get-NovaCliForwardingParameterSet -BoundParameters @{Verbose = $true; Confirm = $false} -IncludeShouldProcess

                $result.Verbose | Should -BeTrue
                $result.WhatIf | Should -BeTrue
                $result.Confirm | Should -BeFalse
            }
            finally {
                $WhatIfPreference = $previousWhatIfPreference
            }
        }
    }

    It 'Get-NovaCliInstalledVersion returns the stable version when prerelease metadata is blank or missing' {
        InModuleScope $script:moduleName {
            $blankPrereleaseModule = [pscustomobject]@{
                Version = [version]'2.0.0'
                PrivateData = [pscustomobject]@{
                    PSData = [pscustomobject]@{
                        Prerelease = '   '
                    }
                }
            }
            $missingPrereleaseModule = [pscustomobject]@{
                Version = [version]'2.0.1'
                PrivateData = [pscustomobject]@{
                    PSData = [pscustomobject]@{}
                }
            }

            Get-NovaCliInstalledVersion -Module $blankPrereleaseModule | Should -Be '2.0.0'
            Get-NovaCliInstalledVersion -Module $missingPrereleaseModule | Should -Be '2.0.1'
        }
    }
}
