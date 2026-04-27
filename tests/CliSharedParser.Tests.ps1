$script:coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
. $script:coverageGapsCliTestSupportPath
$global:cliSharedParserTestSupportFunctionNameList = @(
    'Assert-TestStructuredCliError'
)

foreach ($functionName in $global:cliSharedParserTestSupportFunctionNameList) {
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
    foreach ($functionName in $global:cliSharedParserTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'CLI shared parser helpers' {
    It 'ConvertFrom-NovaCliSwitchArgument maps declarative switch schemas into boolean option sets' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaCliSwitchArgument -Arguments @('--preview', '-i') -TokenMap @{
                '--preview' = 'Preview'
                '-p' = 'Preview'
                '--continuous-integration' = 'ContinuousIntegration'
                '-i' = 'ContinuousIntegration'
            }

            $options.Preview | Should -BeTrue
            $options.ContinuousIntegration | Should -BeTrue
        }
    }

    It 'Get-NovaCliModeArgumentValue supports empty results, mapped values, usage errors, and unknown arguments' {
        InModuleScope $script:moduleName {
            $notificationDefinition = [pscustomobject]@{
                EmptyResult = 'status'
                TokenMap = @{
                    '--enable' = 'enable'
                }
                Usage = [pscustomobject]@{
                    Message = "Unsupported 'nova notification' usage."
                    ErrorId = 'Nova.Validation.UnsupportedNotificationCliUsage'
                }
                UnknownArgumentUsesUsageError = $false
            }
            $updateDefinition = [pscustomobject]@{
                EmptyResult = @{}
                TokenMap = @{}
                Usage = [pscustomobject]@{
                    Message = "Unsupported 'nova update' usage. Use 'nova update'."
                    ErrorId = 'Nova.Validation.UnsupportedUpdateCliUsage'
                }
                UnknownArgumentUsesUsageError = $true
            }

            $emptyResult = Get-NovaCliModeArgumentValue -Arguments @() -Definition $notificationDefinition
            $mappedResult = Get-NovaCliModeArgumentValue -Arguments @('--enable') -Definition $notificationDefinition

            $usageError = $null
            try {
                Get-NovaCliModeArgumentValue -Arguments @('--enable', '--disable') -Definition $notificationDefinition
            }
            catch {
                $usageError = $_
            }

            $unknownArgumentError = $null
            try {
                Get-NovaCliModeArgumentValue -Arguments @('--bogus') -Definition $notificationDefinition
            }
            catch {
                $unknownArgumentError = $_
            }

            $updateUsageError = $null
            try {
                Get-NovaCliModeArgumentValue -Arguments @('--bogus') -Definition $updateDefinition
            }
            catch {
                $updateUsageError = $_
            }

            $emptyResult | Should -Be 'status'
            $mappedResult | Should -Be 'enable'
            Assert-TestStructuredCliError -ThrownError $usageError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported 'nova notification' usage."
                ErrorId = 'Nova.Validation.UnsupportedNotificationCliUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
            })
            Assert-TestStructuredCliError -ThrownError $unknownArgumentError -ExpectedError ([pscustomobject]@{
                Message = 'Unknown argument: --bogus'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--bogus'
            })
            Assert-TestStructuredCliError -ThrownError $updateUsageError -ExpectedError ([pscustomobject]@{
                Message = "Unsupported 'nova update' usage. Use 'nova update'."
                ErrorId = 'Nova.Validation.UnsupportedUpdateCliUsage'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
            })
        }
    }

    It 'the shared parsers preserve the existing routed CLI contracts for bump, version, update, and notification' {
        InModuleScope $script:moduleName {
            $bumpOptions = ConvertFrom-NovaBumpCliArgument -Arguments @('--preview', '--continuous-integration')

            $bumpOptions.Preview | Should -BeTrue
            $bumpOptions.ContinuousIntegration | Should -BeTrue
            (ConvertFrom-NovaVersionCliArgument).Installed | Should -BeFalse
            (ConvertFrom-NovaVersionCliArgument -Arguments @('--installed')).Installed | Should -BeTrue
            ConvertFrom-NovaNotificationCliArgument | Should -Be 'status'
            ConvertFrom-NovaNotificationCliArgument -Arguments @('--enable') | Should -Be 'enable'
            ConvertFrom-NovaNotificationCliArgument -Arguments @('-d') | Should -Be 'disable'
            (ConvertFrom-NovaUpdateCliArgument).Count | Should -Be 0
        }
    }
}
