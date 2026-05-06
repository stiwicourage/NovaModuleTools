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
    'Get-TestNovaCliWhatIfResultMap'
    'Assert-TestNovaCliWhatIfResultMap'
    'Get-TestNovaCliContinuousIntegrationForwardingCaseList'
    'New-TestPesterConfigStub'
    'Get-TestInstalledNovaCliSnapshot'
    'Assert-TestInstalledNovaCliSnapshot'
    'Assert-TestInstalledNovaCliBumpBehavior'
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
        'Get-TestNovaCliWhatIfResultMap'
        'Assert-TestNovaCliWhatIfResultMap'
        'Get-TestNovaCliContinuousIntegrationForwardingCaseList'
        'New-TestPesterConfigStub'
        'Get-TestInstalledNovaCliSnapshot'
        'Assert-TestInstalledNovaCliSnapshot'
        'Assert-TestInstalledNovaCliBumpBehavior'
    )
}

Describe 'Nova command model - standalone CLI override-warning behavior' {
    It 'Invoke-NovaCli forwards override-warning for routed build-aware commands' -ForEach @(
        @{CommandName = 'build'; ActionCommand = 'Invoke-NovaBuild'; Arguments = @('--override-warning')}
        @{CommandName = 'test'; ActionCommand = 'Test-NovaBuild'; Arguments = @('--build', '--override-warning')}
        @{CommandName = 'package'; ActionCommand = 'New-NovaModulePackage'; Arguments = @('--override-warning')}
        @{CommandName = 'publish'; ActionCommand = 'Publish-NovaModule'; Arguments = @('--repository', 'PSGallery', '--api-key', 'key123', '--override-warning')}
        @{CommandName = 'release'; ActionCommand = 'Invoke-NovaRelease'; Arguments = @('--repository', 'PSGallery', '--api-key', 'key123', '--override-warning')}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock $TestCase.ActionCommand {
                [pscustomobject]@{OverrideWarning = $OverrideWarning.IsPresent}
            }

            $result = Invoke-NovaCli -Command $TestCase.CommandName -Arguments $TestCase.Arguments

            $result.OverrideWarning | Should -BeTrue
        }
    }
}
