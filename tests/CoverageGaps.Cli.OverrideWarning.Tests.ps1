$script:coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
$global:coverageGapsCliOverrideWarningTestSupportFunctionNameList = @(
    'Assert-TestStructuredCliError'
)
. $script:coverageGapsCliTestSupportPath

foreach ($functionName in $global:coverageGapsCliOverrideWarningTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $coverageGapsCliTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'CoverageGaps.Cli.TestSupport.ps1')).Path
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $coverageGapsCliTestSupportPath
    foreach ($functionName in $global:coverageGapsCliOverrideWarningTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage gaps for CLI override-warning parsing' {
    It 'ConvertFrom-NovaCliArgument parses override-warning together with delivery options' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaCliArgument -Arguments @('--local', '--path', '/tmp/modules', '--api-key', 'secret', '--skip-tests', '--continuous-integration', '--override-warning')

            $options.Local | Should -BeTrue
            $options.ModuleDirectoryPath | Should -Be '/tmp/modules'
            $options.ApiKey | Should -Be 'secret'
            $options.SkipTests | Should -BeTrue
            $options.ContinuousIntegration | Should -BeTrue
            $options.OverrideWarning | Should -BeTrue
        }
    }

    It 'ConvertFrom-NovaPackageCliArgument accepts override-warning and still rejects publish-only options' {
        InModuleScope $script:moduleName {
            (ConvertFrom-NovaPackageCliArgument -Arguments @('-s')).SkipTests | Should -BeTrue
            (ConvertFrom-NovaPackageCliArgument -Arguments @('-o')).OverrideWarning | Should -BeTrue

            $thrown = $null
            try {
                ConvertFrom-NovaPackageCliArgument -Arguments @('--local')
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredCliError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Unknown argument: --local'
                ErrorId = 'Nova.Validation.UnknownCliArgument'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '--local'
            })
        }
    }
}
