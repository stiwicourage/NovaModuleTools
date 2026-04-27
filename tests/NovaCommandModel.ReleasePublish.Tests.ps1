$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
$global:novaCommandModelTestSupportFunctionNameList = @(
    'Get-TestRegexMatchGroup'
    'ConvertTo-TestNormalizedText'
    'Assert-TestStructuredError'
    'Invoke-TestPublishWorkflowCiRestoreAssertion'
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
$assertStructuredErrorScriptBlock = (Get-Command -Name 'Assert-TestStructuredError' -CommandType Function -ErrorAction Stop).ScriptBlock
Set-Item -Path 'function:global:Assert-TestStructuredError' -Value $assertStructuredErrorScriptBlock

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

    $assertStructuredErrorScriptBlock = (Get-Command -Name 'Assert-TestStructuredError' -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path 'function:global:Assert-TestStructuredError' -Value $assertStructuredErrorScriptBlock
}

Describe 'Nova command model - release and publish behavior' {
    It 'Invoke-NovaReleaseWorkflow preserves the expected step order when <Name>' -ForEach @(
        @{Name = 'tests run'; SkipTestsRequested = $false; ExpectedStepList = @('build', 'test', 'bump', 'build', 'publish'); ExpectedTestCalls = 1}
        @{Name = 'tests are skipped'; SkipTestsRequested = $true; ExpectedStepList = @('build', 'bump', 'build', 'publish'); ExpectedTestCalls = 0}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $script:steps = @()

            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Update-NovaModuleVersion {
                $script:steps += 'bump'
                [pscustomobject]@{NewVersion = '1.0.1'}
            }
            $workflowContext = [pscustomobject]@{
                WorkflowParams = @{}
                SkipTestsRequested = $TestCase.SkipTestsRequested
                PublishInvocation = [pscustomobject]@{
                    Action = {$script:steps += 'publish'}
                }
                PublishParams = @{}
            }

            Invoke-NovaReleaseWorkflow -WorkflowContext $workflowContext | Out-Null

            $script:steps | Should -Be $TestCase.ExpectedStepList
            Assert-MockCalled Test-NovaBuild -Times $TestCase.ExpectedTestCalls
        }
    }

    It 'Invoke-NovaRelease does not bump version when tests fail' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {throw 'boom'}
            Mock Update-NovaModuleVersion {}

            $thrown = $null
            try {
                Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'boom'
            Assert-MockCalled Update-NovaModuleVersion -Times 0
        }
    }

    It 'Invoke-NovaReleaseWorkflow forwards WhatIf to build test bump build and publish helpers' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $publishAction = {
                param($WhatIf)

                $script:steps += "publish:$WhatIf"
            }

            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock Update-NovaModuleVersion {
                $script:steps += "bump:$WhatIfPreference"
                [pscustomobject]@{PreviousVersion = '1.0.0'; NewVersion = '1.0.0'; Label = 'Patch'; CommitCount = 0}
            }
            $workflowContext = [pscustomobject]@{
                WorkflowParams = @{WhatIf = $true}
                PublishInvocation = [pscustomobject]@{
                    Action = $publishAction
                }
                PublishParams = @{WhatIf = $true}
            }

            $result = Invoke-NovaReleaseWorkflow -WorkflowContext $workflowContext

            $script:steps -join ',' | Should -Be 'build:True,test:True,bump:True,build:True,publish:True'
            $result.NewVersion | Should -Be '1.0.0'
        }
    }

    It 'Get-NovaPublishWorkflowContext composes shared release workflow context for local execution' {
        InModuleScope $script:moduleName {
            Mock Resolve-NovaPublishInvocation {
                [pscustomobject]@{
                    Target = '/tmp/modules'
                    IsLocal = $true
                    Parameters = @{
                        ProjectInfo = [pscustomobject]@{ProjectName = 'Ignored'}
                        ModuleDirectoryPath = '/tmp/ignored'
                    }
                    Action = {
                        param($ProjectInfo, $ModuleDirectoryPath)

                        $script:publishBoundParameters = @{}
                        foreach ($parameterName in $PSBoundParameters.Keys) {
                            $script:publishBoundParameters[$parameterName] = $PSBoundParameters[$parameterName]
                        }
                    }
                }
            }
            Mock Get-NovaResolvedPublishParameterMap {
                @{
                    ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                    ModuleDirectoryPath = '/tmp/modules'
                    WhatIf = $true
                }
            }
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                OutputModuleDir = '/tmp/dist/NovaModuleTools'
            }

            $result = Get-NovaPublishWorkflowContext -ProjectInfo $projectInfo -PublishOption @{Local = $true} -WorkflowParams @{WhatIf = $true} -WorkflowSettings @{
                WorkflowName = 'release'
                Release = $true
            }

            Assert-MockCalled Get-NovaResolvedPublishParameterMap -Times 1
            $result.PublishParams.ProjectInfo.ProjectName | Should -Be 'NovaModuleTools'
            $result.PublishParams.ModuleDirectoryPath | Should -Be '/tmp/modules'
            $result.PublishParams.WhatIf | Should -BeTrue
            $result.PublishInvocation.IsLocal | Should -BeTrue
            $result.SkipTestsRequested | Should -BeFalse
            $result.'ContinuousIntegrationRequested' | Should -BeFalse
            $result.Operation | Should -Be 'Run Nova release workflow (build, test, and publish) to local directory'
            $result.LocalPublishActivation | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaPublishWorkflowContext carries delivery workflow flags when requested' -ForEach @(
        @{
            PublishOption = @{Repository = 'PSGallery'; SkipTests = $true}
            WorkflowSettings = @{WorkflowName = 'release'; Release = $true}
            Assert = {
                param($Result)

                $Result.SkipTestsRequested | Should -BeTrue
                $Result.Operation | Should -Be 'Run Nova release workflow (build and publish) to repository'
            }
        }
        @{
            PublishOption = @{Repository = 'PSGallery'; ContinuousIntegration = $true}
            WorkflowSettings = @{WorkflowName = 'publish'}
            Assert = {
                param($Result)

                $Result.'ContinuousIntegrationRequested' | Should -BeTrue
                $Result.ProjectInfo.ProjectName | Should -Be 'NovaModuleTools'
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Resolve-NovaPublishInvocation {
                [pscustomobject]@{
                    Target = 'PSGallery'
                    IsLocal = $false
                    Parameters = @{}
                    Action = {}
                }
            }
            Mock Get-NovaResolvedPublishParameterMap {{}}
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                OutputModuleDir = '/tmp/dist/NovaModuleTools'
            }

            $result = Get-NovaPublishWorkflowContext -ProjectInfo $projectInfo -PublishOption $TestCase.PublishOption -WorkflowSettings $TestCase.WorkflowSettings

            & $TestCase.Assert $result
        }
    }

    It 'Invoke-NovaRelease delegates orchestration to the private release workflow helper' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            }
            Mock Get-NovaPublishWorkflowContext {
                [pscustomobject]@{
                    WorkflowName = 'release'
                    LocalRequested = $true
                    PublishInvocation = [pscustomobject]@{IsLocal = $true}
                    Target = '/tmp/modules'
                    Operation = 'Run Nova release workflow (build, test, and publish) to local directory'
                }
            }
            Mock Write-NovaPublishWorkflowContext {}
            Mock Invoke-NovaReleaseWorkflow {
                [pscustomobject]@{NewVersion = '1.0.1'}
            }

            $result = Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path -Confirm:$false

            $result.NewVersion | Should -Be '1.0.1'
            Assert-MockCalled Get-NovaPublishWorkflowContext -Times 1 -ParameterFilter {$WorkflowSettings.WorkflowName -eq 'release' -and $WorkflowSettings.Release}
            Assert-MockCalled Write-NovaPublishWorkflowContext -Times 1
            Assert-MockCalled Invoke-NovaReleaseWorkflow -Times 1
        }
    }

    It '<CommandName> forwards ContinuousIntegration into its shared workflow context' -ForEach @(
        @{
            CommandName = 'Invoke-NovaRelease'
            WorkflowName = 'release'
            Operation = 'Run Nova release workflow (build, test, and publish) to repository'
            Invoke = {
                Invoke-NovaRelease -PublishOption @{Repository = 'PSGallery'} -ContinuousIntegration -Path (Get-Location).Path -Confirm:$false
            }
        }
        @{
            CommandName = 'Publish-NovaModule'
            WorkflowName = 'publish'
            Operation = 'Build, test, and publish Nova module to repository'
            Invoke = {
                Publish-NovaModule -Repository PSGallery -ApiKey key123 -ContinuousIntegration -Confirm:$false
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            }
            Mock Get-NovaPublishWorkflowContext {
                [pscustomobject]@{
                    WorkflowName = $TestCase.WorkflowName
                    LocalRequested = $false
                    PublishInvocation = [pscustomobject]@{IsLocal = $false}
                    Target = 'PSGallery'
                    Operation = $TestCase.Operation
                }
            }
            Mock Write-NovaPublishWorkflowContext {}
            if ($TestCase.WorkflowName -eq 'release') {
                Mock Invoke-NovaReleaseWorkflow {}
            }
            else {
                Mock Invoke-NovaPublishWorkflow {}
            }

            & $TestCase.Invoke | Out-Null

            Assert-MockCalled Get-NovaPublishWorkflowContext -Times 1 -ParameterFilter {$PublishOption.ContinuousIntegration -and $PublishOption.Repository -eq 'PSGallery'}
        }
    }

    It 'Invoke-NovaRelease defaults Path to the current location when Path is omitted' {
        $expectedPath = (Get-Location).Path

        InModuleScope $script:moduleName -Parameters @{ExpectedPath = $expectedPath} {
            param($ExpectedPath)

            Mock Push-Location {} -ParameterFilter {$LiteralPath -eq $ExpectedPath}
            Mock Pop-Location {}
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            }
            Mock Get-NovaPublishWorkflowContext {
                [pscustomobject]@{
                    WorkflowName = 'release'
                    LocalRequested = $true
                    PublishInvocation = [pscustomobject]@{IsLocal = $true}
                    Target = '/tmp/modules'
                    Operation = 'Run Nova release workflow (build, test, and publish) to local directory'
                }
            }
            Mock Write-NovaPublishWorkflowContext {}
            Mock Invoke-NovaReleaseWorkflow {
                [pscustomobject]@{NewVersion = '1.0.1'}
            }

            $result = Invoke-NovaRelease -PublishOption @{Local = $true} -Confirm:$false

            $result.NewVersion | Should -Be '1.0.1'
            Assert-MockCalled Push-Location -Times 1 -ParameterFilter {$LiteralPath -eq $ExpectedPath}
            Assert-MockCalled Pop-Location -Times 1
            Assert-MockCalled Invoke-NovaReleaseWorkflow -Times 1
        }
    }

    It '<CommandName> forwards SkipTests into its shared workflow context' -ForEach @(
        @{
            CommandName = 'Invoke-NovaRelease'
            WorkflowName = 'release'
            Operation = 'Run Nova release workflow (build and publish) to repository'
            Invoke = {
                Invoke-NovaRelease -PublishOption @{Repository = 'PSGallery'} -SkipTests -Path (Get-Location).Path -Confirm:$false
            }
        }
        @{
            CommandName = 'Publish-NovaModule'
            WorkflowName = 'publish'
            Operation = 'Build, skip tests, and publish Nova module to repository'
            Invoke = {
                Publish-NovaModule -Repository PSGallery -ApiKey key123 -SkipTests -Confirm:$false
            }
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            }
            Mock Get-NovaPublishWorkflowContext {
                [pscustomobject]@{
                    WorkflowName = $TestCase.WorkflowName
                    LocalRequested = $false
                    PublishInvocation = [pscustomobject]@{IsLocal = $false}
                    Target = 'PSGallery'
                    Operation = $TestCase.Operation
                }
            }
            Mock Write-NovaPublishWorkflowContext {}
            if ($TestCase.WorkflowName -eq 'release') {
                Mock Invoke-NovaReleaseWorkflow {}
            }
            else {
                Mock Invoke-NovaPublishWorkflow {}
            }

            & $TestCase.Invoke | Out-Null

            Assert-MockCalled Get-NovaPublishWorkflowContext -Times 1 -ParameterFilter {$PublishOption.SkipTests -and $PublishOption.Repository -eq 'PSGallery'}
        }
    }

    It 'Invoke-NovaPublishWorkflow imports the published local module after a successful local publish' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $localManifestPath = '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            $workflowContext = [pscustomobject]@{
                WorkflowParams = @{}
                PublishInvocation = [pscustomobject]@{
                    Parameters = @{
                        ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                    }
                    Action = {$script:steps += 'publish'}
                }
                PublishParams = @{}
                LocalPublishActivation = [pscustomobject]@{
                    ManifestPath = $localManifestPath
                    ImportAction = {param($ProjectName, $ManifestPath) $script:steps += 'import'}
                }
            }

            {Invoke-NovaPublishWorkflow -WorkflowContext $workflowContext -ShouldRun} | Should -Not -Throw

            $script:steps -join ',' | Should -Be 'build,test,publish,import'
        }
    }

    It 'Invoke-NovaPublishWorkflow restores the built module in CI mode for <Name>' -ForEach @(
        @{
            Name = 'repository publish'
            UseLocalPublishActivation = $false
            ExpectedSteps = 'build,test,publish,ci'
        }
        @{
            Name = 'local publish'
            UseLocalPublishActivation = $true
            ExpectedSteps = 'build,test,publish,import,ci'
        }
    ) {
        Invoke-TestPublishWorkflowCiRestoreAssertion -AssertionCase @{
            ModuleName = $script:moduleName
            TestCase = $_
        }
    }

    It 'Invoke-NovaPublishWorkflow skips tests when SkipTests is requested' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            $workflowContext = [pscustomobject]@{
                WorkflowParams = @{}
                SkipTestsRequested = $true
                PublishInvocation = [pscustomobject]@{
                    Parameters = @{
                        ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                    }
                    Action = {$script:steps += 'publish'}
                }
                PublishParams = @{}
                LocalPublishActivation = $null
            }

            Invoke-NovaPublishWorkflow -WorkflowContext $workflowContext -ShouldRun | Out-Null

            $script:steps -join ',' | Should -Be 'build,publish'
            Assert-MockCalled Test-NovaBuild -Times 0
        }
    }

    It 'Get-NovaPublishedLocalManifestPath resolves the manifest under the local publish directory' {
        InModuleScope $script:moduleName {
            $publishInvocation = [pscustomobject]@{
                IsLocal = $true
                Target = '/tmp/modules'
                Parameters = @{
                    ProjectInfo = [pscustomobject]@{
                        ProjectName = 'NovaModuleTools'
                    }
                }
            }

            $result = Get-NovaPublishedLocalManifestPath -PublishInvocation $publishInvocation

            $result | Should -Be '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
        }
    }

    It 'Invoke-NovaPublishWorkflow forwards WhatIf to build test and publish helpers without importing' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $publishAction = {
                param($WhatIf)

                $script:steps += "publish:$WhatIf"
            }

            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            $workflowContext = [pscustomobject]@{
                WorkflowParams = @{WhatIf = $true}
                PublishInvocation = [pscustomobject]@{
                    Action = $publishAction
                }
                PublishParams = @{WhatIf = $true}
                LocalPublishActivation = [pscustomobject]@{
                    ManifestPath = '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
                    ImportAction = {$script:steps += 'import'}
                }
            }

            $result = Invoke-NovaPublishWorkflow -WorkflowContext $workflowContext

            $result | Should -BeNullOrEmpty
            $script:steps -join ',' | Should -Be 'build:True,test:True,publish:True'
        }
    }

    It 'Invoke-NovaReleaseWorkflow forwards ContinuousIntegration into nested build and bump steps and restores the built module after publish' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Invoke-NovaBuild {
                param([switch]$ContinuousIntegration)

                $script:steps += "build:$( [bool]$ContinuousIntegration )"
            }
            Mock Test-NovaBuild {
                $script:steps += 'test'
            }
            Mock Update-NovaModuleVersion {
                param([switch]$ContinuousIntegration)

                $script:steps += "bump:$( [bool]$ContinuousIntegration )"
                [pscustomobject]@{NewVersion = '1.0.1'}
            }
            Mock Import-NovaBuiltModuleForCi {
                $script:steps += 'ci'
            }
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                WorkflowParams = @{}
                ContinuousIntegrationRequested = $true
                SkipTestsRequested = $false
                PublishInvocation = [pscustomobject]@{
                    Action = {$script:steps += 'publish'}
                }
                PublishParams = @{}
            }

            Invoke-NovaReleaseWorkflow -WorkflowContext $workflowContext | Out-Null

            $script:steps | Should -Be @('build:True', 'test', 'bump:True', 'build:True', 'publish', 'ci')
            Assert-MockCalled Import-NovaBuiltModuleForCi -Times 1 -ParameterFilter {$ProjectInfo.ProjectName -eq 'NovaModuleTools'}
        }
    }

    It 'Publish-NovaModule delegates orchestration to the private publish workflow helper' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            }
            Mock Get-NovaPublishWorkflowContext {
                [pscustomobject]@{
                    WorkflowName = 'publish'
                    LocalRequested = $false
                    PublishInvocation = [pscustomobject]@{IsLocal = $false}
                    Target = 'PSGallery'
                    Operation = 'Build, test, and publish Nova module to repository'
                }
            }
            Mock Write-NovaPublishWorkflowContext {}
            Mock Invoke-NovaPublishWorkflow {}

            {Publish-NovaModule -Repository PSGallery -ApiKey key123 -Confirm:$false} | Should -Not -Throw

            Assert-MockCalled Get-NovaPublishWorkflowContext -Times 1 -ParameterFilter {$WorkflowSettings.WorkflowName -eq 'publish' -and $WorkflowSettings.IncludeLocalPublishActivation}
            Assert-MockCalled Write-NovaPublishWorkflowContext -Times 1
            Assert-MockCalled Invoke-NovaPublishWorkflow -Times 1
        }
    }

    It 'Publish-NovaModule keeps native PowerShell Confirm support for direct cmdlet usage' {
        InModuleScope $script:moduleName {
            $command = Get-Command -Name 'Publish-NovaModule' -CommandType Function -ErrorAction Stop

            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
        }
    }

    It 'Publish-NovaBuiltModuleToRepository resolves API key precedence clearly when <Name>' -ForEach @(
        @{
            Name = 'an explicit API key overrides the PSGallery environment fallback'
            Repository = 'PSGallery'
            ApiKey = 'explicit-gallery-key'
            EnvironmentApiKey = 'environment-gallery-key'
            ExpectedApiKey = 'explicit-gallery-key'
        }
        @{
            Name = 'PSGallery falls back to PSGALLERY_API when ApiKey is omitted'
            Repository = 'PSGallery'
            ApiKey = $null
            EnvironmentApiKey = 'environment-gallery-key'
            ExpectedApiKey = 'environment-gallery-key'
        }
    ) {
        $originalApiKey = [System.Environment]::GetEnvironmentVariable('PSGALLERY_API')

        try {
            [System.Environment]::SetEnvironmentVariable('PSGALLERY_API', $_.EnvironmentApiKey, 'Process')

            InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
                param($TestCase)

                Mock Publish-PSResource {}

                Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist'}) -Repository $TestCase.Repository -ApiKey $TestCase.ApiKey

                Assert-MockCalled Publish-PSResource -Times 1 -ParameterFilter {
                    $Path -eq '/tmp/dist' -and
                            $Repository -eq $TestCase.Repository -and
                            $ApiKey -eq $TestCase.ExpectedApiKey
                }
            }
        }
        finally {
            [System.Environment]::SetEnvironmentVariable('PSGALLERY_API', $originalApiKey, 'Process')
        }
    }

    It 'Publish-NovaBuiltModuleToRepository does not reuse the PSGallery fallback for other repositories' {
        $originalApiKey = [System.Environment]::GetEnvironmentVariable('PSGALLERY_API')

        try {
            [System.Environment]::SetEnvironmentVariable('PSGALLERY_API', 'environment-gallery-key', 'Process')

            InModuleScope $script:moduleName {
                Mock Publish-PSResource {}

                Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist'}) -Repository 'InternalFeed'

                Assert-MockCalled Publish-PSResource -Times 1 -ParameterFilter {
                    $Path -eq '/tmp/dist' -and
                            $Repository -eq 'InternalFeed' -and
                            -not $PSBoundParameters.ContainsKey('ApiKey')
                }
            }
        }
        finally {
            [System.Environment]::SetEnvironmentVariable('PSGALLERY_API', $originalApiKey, 'Process')
        }
    }

    It 'Get-NovaPackageWorkflowContext resolves package metadata, target, and operation for all requested package types' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
            }
            $packageMetadataList = @(
                [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                [pscustomobject]@{Type = 'Zip'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'}
            )

            Mock Get-NovaPackageMetadataList {$packageMetadataList}
            Mock Assert-NovaPackageMetadata {}

            $result = Get-NovaPackageWorkflowContext -ProjectInfo $projectInfo -WorkflowParams @{WhatIf = $true} -ModulePath '/tmp/NovaModuleTools.psm1'

            $result.ProjectInfo.ProjectName | Should -Be 'NovaModuleTools'
            $result.WorkflowParams.WhatIf | Should -BeTrue
            $result.ModulePath | Should -Be '/tmp/NovaModuleTools.psm1'
            $result.Target | Should -Be '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg, /tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'
            $result.SkipTestsRequested | Should -BeFalse
            $result.Operation | Should -Be 'Create package artifacts from built and tested module output'
            $result.PackageMetadataList.Type | Should -Be @('NuGet', 'Zip')
            Assert-MockCalled Get-NovaPackageMetadataList -Times 1 -ParameterFilter {$ProjectInfo.ProjectName -eq 'NovaModuleTools'}
            Assert-MockCalled Assert-NovaPackageMetadata -Times 2
        }
    }

    It 'Get-NovaPackageWorkflowContext carries SkipTestsRequested into package operation text' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
            }
            $packageMetadataList = @(
                [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
            )

            Mock Get-NovaPackageMetadataList {$packageMetadataList}
            Mock Assert-NovaPackageMetadata {}

            $result = Get-NovaPackageWorkflowContext -ProjectInfo $projectInfo -SkipTestsRequested

            $result.SkipTestsRequested | Should -BeTrue
            $result.Operation | Should -Be 'Create NuGet package from built module output with tests skipped'
        }
    }

    It 'Get-NovaPackageWorkflowContext uses the single-package operation wording when exactly one package is requested' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
            }
            $packageMetadataList = @(
                [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
            )

            Mock Get-NovaPackageMetadataList {$packageMetadataList}
            Mock Assert-NovaPackageMetadata {}

            $result = Get-NovaPackageWorkflowContext -ProjectInfo $projectInfo

            $result.Operation | Should -Be 'Create NuGet package from built and tested module output'
            $result.Target | Should -Be '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'
            Assert-MockCalled Assert-NovaPackageMetadata -Times 1
        }
    }

    It 'Invoke-NovaPackageWorkflow runs build, test, and package creation in order for all requested package types' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                WorkflowParams = @{}
                PackageMetadataList = @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                    [pscustomobject]@{Type = 'Zip'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'}
                )
                ModulePath = '/tmp/NovaModuleTools.psm1'
            }

            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Invoke-NovaPackageArtifactCreation {
                $script:steps += 'pack'
                @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                    [pscustomobject]@{Type = 'Zip'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'}
                )
            }

            $result = @(Invoke-NovaPackageWorkflow -WorkflowContext $workflowContext -ShouldRun)

            $script:steps -join ',' | Should -Be 'build,test,pack'
            $result.Type | Should -Be @('NuGet', 'Zip')
            $result.PackagePath | Should -Be @(
                '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg',
                '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'
            )
            Assert-MockCalled Invoke-NovaBuild -Times 1
            Assert-MockCalled Test-NovaBuild -Times 1
            Assert-MockCalled Invoke-NovaPackageArtifactCreation -Times 1 -ParameterFilter {
                $WorkflowContext.ProjectInfo.ProjectName -eq 'NovaModuleTools' -and
                        $WorkflowContext.PackageMetadataList.Count -eq 2 -and
                        $WorkflowContext.ModulePath -eq '/tmp/NovaModuleTools.psm1'
            }
        }
    }

    It 'Invoke-NovaPackageWorkflow skips tests when SkipTests is requested' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                WorkflowParams = @{}
                SkipTestsRequested = $true
                PackageMetadataList = @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                )
                ModulePath = '/tmp/NovaModuleTools.psm1'
            }

            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Invoke-NovaPackageArtifactCreation {
                $script:steps += 'pack'
                @([pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'})
            }

            $result = @(Invoke-NovaPackageWorkflow -WorkflowContext $workflowContext -ShouldRun)

            $script:steps -join ',' | Should -Be 'build,pack'
            $result.Type | Should -Be @('NuGet')
            Assert-MockCalled Test-NovaBuild -Times 0
        }
    }

    It 'Invoke-NovaPackageArtifactCreation reimports the current module when package helpers were unloaded during tests' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
            }
            $packageMetadataList = @(
                [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                [pscustomobject]@{Type = 'Zip'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'}
            )

            Mock Get-Command {
                $null
            } -ParameterFilter {$Name -eq 'New-NovaPackageArtifacts' -and $CommandType -eq 'Function'}
            Mock Import-Module {
                $ExecutionContext.SessionState.Module
            } -ParameterFilter {$Name -eq $ExecutionContext.SessionState.Module.Path -and $PassThru}
            Mock New-NovaPackageArtifacts {
                $script:steps += 'pack'
                @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                    [pscustomobject]@{Type = 'Zip'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.zip'}
                )
            }

            $workflowContext = [pscustomobject]@{
                ProjectInfo = $projectInfo
                PackageMetadataList = $packageMetadataList
                ModulePath = $ExecutionContext.SessionState.Module.Path
            }

            $result = @(Invoke-NovaPackageArtifactCreation -WorkflowContext $workflowContext)

            $script:steps -join ',' | Should -Be 'pack'
            $result.Type | Should -Be @('NuGet', 'Zip')
            Assert-MockCalled Import-Module -Times 1 -ParameterFilter {$Name -eq $ExecutionContext.SessionState.Module.Path -and $PassThru}
        }
    }

    It 'Invoke-NovaPackageArtifactCreation uses the loaded package helper directly when it is already available' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
            }
            $packageMetadataList = @(
                [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
            )

            Mock Get-Command {
                [pscustomobject]@{Name = 'New-NovaPackageArtifacts'}
            } -ParameterFilter {$Name -eq 'New-NovaPackageArtifacts' -and $CommandType -eq 'Function'}
            Mock New-NovaPackageArtifacts {
                @([pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'})
            }
            Mock Import-Module {throw 'should not import'}

            $workflowContext = [pscustomobject]@{
                ProjectInfo = $projectInfo
                PackageMetadataList = $packageMetadataList
                ModulePath = '/tmp/NovaModuleTools.psm1'
            }

            $result = @(Invoke-NovaPackageArtifactCreation -WorkflowContext $workflowContext)

            $result.Type | Should -Be @('NuGet')
            Assert-MockCalled New-NovaPackageArtifacts -Times 1 -ParameterFilter {
                $ProjectInfo.ProjectName -eq 'NovaModuleTools' -and $PackageMetadataList.Count -eq 1
            }
            Assert-MockCalled Import-Module -Times 0
        }
    }

    It 'New-NovaModulePackage delegates orchestration to the private package workflow helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaPackageWorkflowContext {
                [pscustomobject]@{
                    ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                    WorkflowParams = @{}
                    PackageMetadataList = @(
                        [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                    )
                    ModulePath = '/tmp/NovaModuleTools.psm1'
                    Target = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'
                    Operation = 'Create NuGet package from built and tested module output'
                }
            }
            Mock Invoke-NovaPackageWorkflow {
                @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                )
            }

            $result = @(New-NovaModulePackage -Confirm:$false)

            $result.Type | Should -Be @('NuGet')
            $result.PackagePath | Should -Be @('/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg')
            Assert-MockCalled Get-NovaPackageWorkflowContext -Times 1
            Assert-MockCalled Invoke-NovaPackageWorkflow -Times 1 -ParameterFilter {
                $ShouldRun -and
                        $WorkflowContext.Target -eq '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg' -and
                        $WorkflowContext.Operation -eq 'Create NuGet package from built and tested module output'
            }
        }
    }

    It 'New-NovaModulePackage forwards SkipTests into the package workflow context' {
        InModuleScope $script:moduleName {
            Mock Get-NovaPackageWorkflowContext {
                [pscustomobject]@{
                    ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                    WorkflowParams = @{}
                    SkipTestsRequested = $true
                    PackageMetadataList = @(
                        [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                    )
                    ModulePath = '/tmp/NovaModuleTools.psm1'
                    Target = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'
                    Operation = 'Create NuGet package from built module output with tests skipped'
                }
            }
            Mock Invoke-NovaPackageWorkflow {}

            New-NovaModulePackage -SkipTests -Confirm:$false | Out-Null

            Assert-MockCalled Get-NovaPackageWorkflowContext -Times 1 -ParameterFilter {$SkipTestsRequested}
        }
    }

    It 'Invoke-NovaPackageWorkflow -WhatIf forwards preview mode through build and test without creating a package' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                WorkflowParams = @{WhatIf = $true}
                PackageMetadataList = @(
                    [pscustomobject]@{Type = 'NuGet'; PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
                )
                ModulePath = '/tmp/NovaModuleTools.psm1'
            }

            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock Invoke-NovaPackageArtifactCreation {throw 'should not package'}

            $result = Invoke-NovaPackageWorkflow -WorkflowContext $workflowContext

            $result | Should -BeNullOrEmpty
            $script:steps -join ',' | Should -Be 'build:True,test:True'
            Assert-MockCalled Invoke-NovaPackageArtifactCreation -Times 0
        }
    }

    It 'Get-NovaPackageMetadata reuses project.json and Manifest metadata by default' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'PackageProject'
                Version = '2.3.4'
                ProjectRoot = '/tmp/project'
                Description = 'Top-level description'
                Manifest = [ordered]@{
                    Author = 'Author One'
                    Tags = @('Nova', 'Packaging')
                    ProjectUri = 'https://example.test/project'
                    ReleaseNotes = 'https://example.test/release-notes'
                    LicenseUri = 'https://example.test/license'
                }
                Package = [ordered]@{
                    Id = 'PackageProject'
                    Types = @('NuGet')
                    OutputDirectory = [ordered]@{
                        Path = '/tmp/project/artifacts/packages'
                        Clean = $true
                    }
                    PackageFileName = 'PackageProject.2.3.4.nupkg'
                    Authors = 'Author One'
                    Description = 'Top-level description'
                }
            }

            $result = Get-NovaPackageMetadata -ProjectInfo $projectInfo

            $result.Type | Should -Be 'NuGet'
            $result.Id | Should -Be 'PackageProject'
            $result.Version | Should -Be '2.3.4'
            $result.Authors | Should -Be @('Author One')
            $result.Description | Should -Be 'Top-level description'
            $result.Tags | Should -Be @('Nova', 'Packaging')
            $result.ProjectUrl | Should -Be 'https://example.test/project'
            $result.ReleaseNotes | Should -Be 'https://example.test/release-notes'
            $result.LicenseUrl | Should -Be 'https://example.test/license'
            $result.OutputDirectory | Should -Be '/tmp/project/artifacts/packages'
            $result.CleanOutputDirectory | Should -BeTrue
            $result.PackagePath | Should -Be '/tmp/project/artifacts/packages/PackageProject.2.3.4.nupkg'
        }
    }

    It 'Get-NovaPackageMetadataList returns one metadata object per requested package type' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'PackageProject'
                Version = '2.3.4'
                ProjectRoot = '/tmp/project'
                Description = 'Top-level description'
                Manifest = [ordered]@{
                    Author = 'Author One'
                    Tags = @('Nova', 'Packaging')
                }
                Package = [ordered]@{
                    Id = 'PackageProject'
                    Types = @('NuGet', 'Zip')
                    OutputDirectory = [ordered]@{
                        Path = '/tmp/project/artifacts/packages'
                        Clean = $true
                    }
                    PackageFileName = 'PackageProject.2.3.4.nupkg'
                    Authors = 'Author One'
                    Description = 'Top-level description'
                }
            }

            $result = @(Get-NovaPackageMetadataList -ProjectInfo $projectInfo)

            $result.Type | Should -Be @('NuGet', 'Zip')
            $result.PackageFileName | Should -Be @('PackageProject.2.3.4.nupkg', 'PackageProject.2.3.4.zip')
            $result.PackagePath | Should -Be @(
                '/tmp/project/artifacts/packages/PackageProject.2.3.4.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.2.3.4.zip'
            )
        }
    }

    It 'Get-NovaPackageMetadataList also returns latest-named metadata when Package.Latest is true' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'PackageProject'
                Version = '2.3.4'
                ProjectRoot = '/tmp/project'
                Description = 'Top-level description'
                Manifest = [ordered]@{
                    Author = 'Author One'
                    Tags = @('Nova', 'Packaging')
                }
                Package = [ordered]@{
                    Id = 'PackageProject'
                    Types = @('NuGet', 'Zip')
                    Latest = $true
                    OutputDirectory = [ordered]@{
                        Path = '/tmp/project/artifacts/packages'
                        Clean = $true
                    }
                    PackageFileName = 'PackageProject.2.3.4.nupkg'
                    Authors = 'Author One'
                    Description = 'Top-level description'
                }
            }

            $result = @(Get-NovaPackageMetadataList -ProjectInfo $projectInfo)

            $result.Type | Should -Be @('NuGet', 'NuGet', 'Zip', 'Zip')
            $result.Latest | Should -Be @($false, $true, $false, $true)
            $result.PackageFileName | Should -Be @(
                'PackageProject.2.3.4.nupkg',
                'PackageProject.latest.nupkg',
                'PackageProject.2.3.4.zip',
                'PackageProject.latest.zip'
            )
            $result.PackagePath | Should -Be @(
                '/tmp/project/artifacts/packages/PackageProject.2.3.4.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.latest.nupkg',
                '/tmp/project/artifacts/packages/PackageProject.2.3.4.zip',
                '/tmp/project/artifacts/packages/PackageProject.latest.zip'
            )
        }
    }

    It 'Get-NovaPackageMetadataList resolves custom PackageFileName versioning when <Name>' -ForEach @(
        @{
            Name = 'AddVersionToFileName appends the project version'
            PackageFileName = 'AgentInstaller'
        }
        @{
            Name = 'PackageFileName already ends with the current version'
            PackageFileName = 'AgentInstaller.2.3.4.zip'
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $projectInfo = [pscustomobject]@{
                ProjectName = 'PackageProject'
                Version = '2.3.4'
                ProjectRoot = '/tmp/project'
                Description = 'Top-level description'
                Manifest = [ordered]@{
                    Author = 'Author One'
                    Tags = @('Nova', 'Packaging')
                }
                Package = [ordered]@{
                    Id = 'PackageProject'
                    Types = @('NuGet', 'Zip')
                    Latest = $true
                    OutputDirectory = [ordered]@{
                        Path = '/tmp/project/artifacts/packages'
                        Clean = $true
                    }
                    PackageFileName = $TestCase.PackageFileName
                    AddVersionToFileName = $true
                    Authors = 'Author One'
                    Description = 'Top-level description'
                }
            }

            $result = @(Get-NovaPackageMetadataList -ProjectInfo $projectInfo)

            $result.PackageFileName | Should -Be @(
                'AgentInstaller.2.3.4.nupkg',
                'AgentInstaller.latest.nupkg',
                'AgentInstaller.2.3.4.zip',
                'AgentInstaller.latest.zip'
            )
        }
    }

    It 'Get-NovaPackageMetadata keeps schema-optional manifest fields empty when they are omitted' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'PackageProject'
                Version = '2.3.4'
                ProjectRoot = '/tmp/project'
                Description = 'Top-level description'
                Manifest = [ordered]@{
                    Author = 'Author One'
                }
                Package = [ordered]@{
                    Id = 'PackageProject'
                    Types = @('NuGet')
                    OutputDirectory = [ordered]@{
                        Path = '/tmp/project/artifacts/packages'
                        Clean = $true
                    }
                    PackageFileName = 'PackageProject.2.3.4.nupkg'
                    Authors = 'Author One'
                    Description = 'Top-level description'
                }
            }

            $result = Get-NovaPackageMetadata -ProjectInfo $projectInfo

            $result.Tags | Should -Be @()
            $result.ProjectUrl | Should -Be ''
            $result.ReleaseNotes | Should -Be ''
            $result.LicenseUrl | Should -Be ''
        }
    }

    It 'New-NovaModulePackage fails with a clear message when package metadata is missing' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    Version = '1.2.3'
                    ProjectRoot = '/tmp/project'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    Description = 'Package test'
                    Manifest = [ordered]@{
                        Author = ''
                        Tags = @()
                        ProjectUri = ''
                        ReleaseNotes = ''
                        LicenseUri = ''
                    }
                    Package = [ordered]@{
                        Id = 'NovaModuleTools'
                        OutputDirectory = [ordered]@{
                            Path = '/tmp/project/artifacts/packages'
                            Clean = $true
                        }
                        PackageFileName = 'NovaModuleTools.1.2.3.nupkg'
                        Authors = @()
                        Description = 'Package test'
                    }
                }
            }
            Mock Invoke-NovaBuild {throw 'should not build'}
            Mock Test-NovaBuild {throw 'should not test'}

            $thrown = $null
            try {
                New-NovaModulePackage
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Missing package metadata value: Authors'
                ErrorId = 'Nova.Configuration.PackageMetadataValueMissing'
                Category = [System.Management.Automation.ErrorCategory]::InvalidData
                TargetObject = 'Authors'
            })
            Assert-MockCalled Invoke-NovaBuild -Times 0
            Assert-MockCalled Test-NovaBuild -Times 0
        }
    }

    It 'Get-ResourceFilePath prefers project src resources during build' {
        InModuleScope $script:moduleName {
            $expected = [System.IO.Path]::GetFullPath('/tmp/project/src/resources/Schema-Build.json')
            $script:checkedPaths = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ResourcesDir = '/tmp/project/src/resources'
                }
            }
            Mock Test-Path {
                param($LiteralPath)

                $script:checkedPaths += $LiteralPath
                return $LiteralPath -eq $expected
            }

            $result = Get-ResourceFilePath -FileName 'Schema-Build.json'

            $result | Should -Be $expected
            $script:checkedPaths[0] | Should -Be $expected
        }
    }

    It 'Get-LocalModulePath returns the first matching local module path for the current platform' {
        InModuleScope $script:moduleName {
            $originalModulePath = $env:PSModulePath
            $script:expectedModulePath = if ($IsWindows) {
                'C:\Users\Stiwi\Documents\PowerShell\Modules'
            }
            else {
                '/Users/stiwi.courage/.local/share/powershell/Modules'
            }

            $env:PSModulePath = if ($IsWindows) {
                'C:\Program Files\PowerShell\Modules;C:\Users\Stiwi\Documents\PowerShell\Modules;C:\Temp\Modules'
            }
            else {
                '/usr/local/share/powershell/Modules:/Users/stiwi.courage/.local/share/powershell/Modules:/tmp/modules'
            }

            Mock Test-Path {
                param($Path)
                return $Path -eq $script:expectedModulePath
            }

            try {
                Get-LocalModulePath | Should -Be $script:expectedModulePath
            }
            finally {
                $env:PSModulePath = $originalModulePath
            }
        }
    }

    It 'Get-LocalModulePath throws a platform-specific error when no matching path exists' {
        InModuleScope $script:moduleName {
            $originalModulePath = $env:PSModulePath
            $env:PSModulePath = if ($IsWindows) {
                'C:\Program Files\PowerShell\Modules;C:\Temp\Modules'
            }
            else {
                '/usr/local/share/powershell/Modules:/tmp/modules'
            }

            Mock Test-Path {$false}

            $expectedMessage = if ($IsWindows) {
                'No windows module path matching*'
            }
            else {
                'No macOS/Linux module path matching*'
            }

            try {
                $thrown = $null
                try {
                    Get-LocalModulePath
                }
                catch {
                    $thrown = $_
                }

                Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                    Message = $expectedMessage
                    ErrorId = 'Nova.Environment.LocalModulePathNotFound'
                    Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                    TargetObject = if ($IsWindows) {
                        '\\Documents\\PowerShell\\Modules'
                    }
                    else {
                        '/\.local/share/powershell/Modules$'
                    }
                })
            }
            finally {
                $env:PSModulePath = $originalModulePath
            }
        }
    }

    It 'Import-NovaPublishedLocalModule exposes a structured error when the local manifest is missing' {
        InModuleScope $script:moduleName {
            $thrown = $null
            try {
                Import-NovaPublishedLocalModule -ProjectName 'NovaModuleTools' -ManifestPath '/tmp/missing/NovaModuleTools.psd1'
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Expected locally published module manifest at: /tmp/missing/NovaModuleTools.psd1'
                ErrorId = 'Nova.Environment.LocalPublishedModuleManifestNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = '/tmp/missing/NovaModuleTools.psd1'
            })
        }
    }

    It 'built module keeps Publish-NovaModule local path resolution before build and test' {
        $packagedModulePath = (Get-Module $script:moduleName).Path

        Test-Path -LiteralPath $packagedModulePath | Should -BeTrue

        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($packagedModulePath, [ref]$tokens, [ref]$errors)

        $errors.Count | Should -Be 0

        $publishFunction = $ast.Find(
                {
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                            $node.Name -eq 'Publish-NovaModule'
                },
                $true
        )

        $publishFunction | Should -Not -BeNullOrEmpty
        $publishSource = $publishFunction.Extent.Text

        $publishSource.IndexOf('Get-NovaPublishWorkflowContext') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Invoke-NovaPublishWorkflow') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Get-NovaPublishWorkflowContext') | Should -BeLessThan $publishSource.IndexOf('Invoke-NovaPublishWorkflow')
    }
}
