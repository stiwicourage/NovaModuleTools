$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
$script:packageUploadTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.PackageUpload.TestSupport.ps1')).Path
$global:novaCommandModelTestSupportFunctionNameList = @(
    'Get-TestRegexMatchGroup'
    'ConvertTo-TestNormalizedText'
    'Assert-TestStructuredError'
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
. $script:packageUploadTestSupportPath

foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}
foreach ($functionName in $global:novaCommandModelPackageUploadTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}
$assertStructuredErrorScriptBlock = (Get-Command -Name 'Assert-TestStructuredError' -CommandType Function -ErrorAction Stop).ScriptBlock
Set-Item -Path 'function:global:Assert-TestStructuredError' -Value $assertStructuredErrorScriptBlock

BeforeAll {
    $testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
    $packageUploadTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.PackageUpload.TestSupport.ps1')).Path
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
    . $packageUploadTestSupportPath
    foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    foreach ($functionName in $global:novaCommandModelPackageUploadTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    $assertStructuredErrorScriptBlock = (Get-Command -Name 'Assert-TestStructuredError' -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path 'function:global:Assert-TestStructuredError' -Value $assertStructuredErrorScriptBlock
}

Describe 'Nova command model - package upload behavior' {
    It 'Get-NovaPackageUploadWorkflowContext resolves project info, normalized upload options, and upload artifacts' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'workflow-context-upload')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            $uploadOption = [pscustomobject]@{
                PackagePath = @($PackagePath)
                PackageType = @('Zip')
                Url = 'https://packages.example/raw/'
                Repository = ''
                UploadPath = 'modules'
                Headers = [ordered]@{}
                Token = $null
                TokenEnvironmentVariable = $null
                AuthenticationScheme = $null
            }
            $uploadArtifactList = @(
                [pscustomobject]@{
                    Type = 'Zip'
                    PackagePath = $PackagePath
                    PackageFileName = 'PackageProject.2.3.4.zip'
                    Repository = ''
                    Headers = [ordered]@{}
                    UploadUrl = 'https://packages.example/raw/modules/PackageProject.2.3.4.zip'
                }
            )

            Mock Resolve-NovaPackageUploadInvocation {$uploadArtifactList}

            $result = Get-NovaPackageUploadWorkflowContext -BoundParameters @{PackagePath = @($PackagePath); Url = 'https://packages.example/raw/'} -ProjectInfo $ProjectInfo -UploadOption $uploadOption

            $result.ProjectInfo.ProjectRoot | Should -Be $ProjectInfo.ProjectRoot
            $result.UploadOption.Url | Should -Be 'https://packages.example/raw/'
            $result.UploadArtifactList.Count | Should -Be 1
            $result.UploadArtifactList[0].UploadUrl | Should -Be 'https://packages.example/raw/modules/PackageProject.2.3.4.zip'
            Assert-MockCalled Resolve-NovaPackageUploadInvocation -Times 1 -ParameterFilter {$UploadOption.Url -eq 'https://packages.example/raw/'}
        }
    }

    It 'Get-NovaPackageUploadWorkflowContext falls back to project-info and upload-option resolution when explicit inputs are omitted' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectRoot = '/tmp/project'; ProjectName = 'PackageProject'}
            }
            Mock New-NovaPackageUploadOption {
                [pscustomobject]@{
                    PackagePath = @('/tmp/project/artifacts/packages/PackageProject.2.3.4.zip')
                    PackageType = @('Zip')
                    Url = 'https://packages.example/raw/'
                    Repository = ''
                    UploadPath = 'modules'
                    Headers = [ordered]@{}
                    Token = $null
                    TokenEnvironmentVariable = $null
                    AuthenticationScheme = $null
                }
            }
            Mock Resolve-NovaPackageUploadInvocation {
                @([pscustomobject]@{Type = 'Zip'; PackageFileName = 'PackageProject.2.3.4.zip'; UploadUrl = 'https://packages.example/raw/modules/PackageProject.2.3.4.zip'})
            }

            $result = Get-NovaPackageUploadWorkflowContext -BoundParameters @{Url = 'https://packages.example/raw/'}

            $result.ProjectInfo.ProjectName | Should -Be 'PackageProject'
            $result.UploadOption.Url | Should -Be 'https://packages.example/raw/'
            $result.UploadArtifactList.Count | Should -Be 1
            $result.Target | Should -Be 'https://packages.example/raw/modules/PackageProject.2.3.4.zip'
            $result.Operation | Should -Be 'Upload Zip package artifact PackageProject.2.3.4.zip'
            Assert-MockCalled Get-NovaProjectInfo -Times 1
            Assert-MockCalled New-NovaPackageUploadOption -Times 1 -ParameterFilter {$BoundParameters.Url -eq 'https://packages.example/raw/'}
        }
    }

    It 'Invoke-NovaPackageUploadWorkflow uploads each approved artifact in order' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $workflowContext = [pscustomobject]@{
                UploadArtifactList = @(
                    [pscustomobject]@{PackageFileName = 'PackageProject.2.3.4.nupkg'}
                    [pscustomobject]@{PackageFileName = 'PackageProject.2.3.4.zip'}
                )
            }
            $approvedUploadArtifactList = @(
                [pscustomobject]@{PackageFileName = 'PackageProject.2.3.4.nupkg'}
                [pscustomobject]@{PackageFileName = 'PackageProject.2.3.4.zip'}
            )

            Mock Invoke-NovaPackageArtifactUpload {
                $script:steps += $UploadArtifact.PackageFileName
                [pscustomobject]@{PackageFileName = $UploadArtifact.PackageFileName; StatusCode = 200}
            }

            $result = @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $workflowContext -UploadArtifactList $approvedUploadArtifactList)

            $script:steps | Should -Be @('PackageProject.2.3.4.nupkg', 'PackageProject.2.3.4.zip')
            $result.PackageFileName | Should -Be @('PackageProject.2.3.4.nupkg', 'PackageProject.2.3.4.zip')
            Assert-MockCalled Invoke-NovaPackageArtifactUpload -Times 2
        }
    }

    It 'Invoke-NovaPackageUploadWorkflow returns an empty result when no approved or resolved artifacts exist' {
        InModuleScope $script:moduleName {
            $workflowContext = [pscustomobject]@{
                UploadArtifactList = @()
            }
            Mock Invoke-NovaPackageArtifactUpload {throw 'should not upload'}

            $result = @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $workflowContext -UploadArtifactList @())

            $result.Count | Should -Be 0
            Assert-MockCalled Invoke-NovaPackageArtifactUpload -Times 0
        }
    }

    It 'Resolve-NovaPackageUploadInvocation orchestrates file, target, header, and artifact resolution' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'PackageProject'
            }
            $uploadOption = [pscustomobject]@{
                PackagePath = @('/tmp/project/artifacts/packages/PackageProject.2.3.4.zip')
                PackageType = @('Zip')
                Url = 'https://packages.example/raw/'
                Repository = 'LocalRaw'
                UploadPath = 'modules'
                Headers = [ordered]@{}
                Token = $null
                TokenEnvironmentVariable = $null
                AuthenticationScheme = $null
            }
            $uploadFileList = @(
                [pscustomobject]@{
                    Type = 'Zip'
                    PackagePath = '/tmp/project/artifacts/packages/PackageProject.2.3.4.zip'
                    PackageFileName = 'PackageProject.2.3.4.zip'
                }
            )
            $uploadTarget = [pscustomobject]@{
                Repository = 'LocalRaw'
                Url = 'https://packages.example/raw/'
                UploadPath = 'modules'
            }
            $uploadHeaders = [ordered]@{
                'X-Trace-Id' = 'trace-123'
            }

            Mock Get-NovaPackageUploadFileList {$uploadFileList}
            Mock Resolve-NovaPackageUploadTarget {$uploadTarget}
            Mock Resolve-NovaPackageUploadHeaders {$uploadHeaders}
            Mock Get-NovaPackageUploadArtifact {
                [pscustomobject]@{
                    Type = $PackageFileInfo.Type
                    PackagePath = $PackageFileInfo.PackagePath
                    PackageFileName = $PackageFileInfo.PackageFileName
                    Repository = $UploadTarget.Repository
                    Headers = $UploadHeaders
                    UploadUrl = 'https://packages.example/raw/modules/PackageProject.2.3.4.zip'
                }
            }

            $result = @(Resolve-NovaPackageUploadInvocation -ProjectInfo $projectInfo -UploadOption $uploadOption)

            $result.Count | Should -Be 1
            $result[0].Type | Should -Be 'Zip'
            $result[0].Repository | Should -Be 'LocalRaw'
            $result[0].Headers['X-Trace-Id'] | Should -Be 'trace-123'
            $result[0].UploadUrl | Should -Be 'https://packages.example/raw/modules/PackageProject.2.3.4.zip'
            Assert-MockCalled Get-NovaPackageUploadFileList -Times 1 -ParameterFilter {$ProjectInfo.ProjectName -eq 'PackageProject' -and $PackageType -eq @('Zip')}
            Assert-MockCalled Resolve-NovaPackageUploadTarget -Times 1 -ParameterFilter {$ProjectInfo.ProjectName -eq 'PackageProject' -and $Repository -eq 'LocalRaw' -and $UploadPath -eq 'modules'}
            Assert-MockCalled Resolve-NovaPackageUploadHeaders -Times 1 -ParameterFilter {$UploadTarget.Repository -eq 'LocalRaw' -and $UploadOption.Repository -eq 'LocalRaw'}
            Assert-MockCalled Get-NovaPackageUploadArtifact -Times 1 -ParameterFilter {$PackageFileInfo.PackageFileName -eq 'PackageProject.2.3.4.zip' -and $UploadTarget.Repository -eq 'LocalRaw'}
        }
    }

    It 'Resolve-NovaPackageUploadTarget resolves target precedence correctly when <Name>' -ForEach (Get-TestNovaPackageUploadTargetResolutionCases) {
        $testCase = $_
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive $testCase.ProjectRootName)
        $repositoryList = Get-TestNovaPackageUploadRepositoryList -ExpectedTraceId $testCase.ExpectedTraceId

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{
                RepositoryUrl = 'https://packages.example/raw/package/'
                UploadPath = 'package-path'
                Headers = [ordered]@{
                    'X-Package-Only' = 'package-only'
                }
                Auth = [ordered]@{
                    HeaderName = 'X-Package-Token'
                    TokenEnvironmentVariable = 'PACKAGE_UPLOAD_TOKEN'
                    Token = 'package-token'
                }
                Repositories = $repositoryList
            })
            TestCase = $testCase
        } {
            param($ProjectInfo, $TestCase)

            $result = if ($TestCase.UseExplicitOverride) {
                Resolve-NovaPackageUploadTarget -ProjectInfo $ProjectInfo -Repository 'LocalRaw' -Url 'https://override.example/upload/' -UploadPath 'manual/path'
            }
            else {
                Resolve-NovaPackageUploadTarget -ProjectInfo $ProjectInfo -Repository 'localraw'
            }

            Assert-TestNovaPackageUploadTargetResolutionResult -Result $result -TestCase $TestCase
        }
    }

    It 'Resolve-NovaPackageUploadHeaders handles auth resolution scenarios correctly' {
        foreach ($testCase in @(Get-TestNovaPackageUploadHeaderResolutionCases)) {
            InModuleScope $script:moduleName -Parameters @{TestCase = $testCase} {
                param($TestCase)

                $result = Resolve-NovaPackageUploadHeaders -UploadTarget $TestCase.UploadTarget -UploadOption $TestCase.UploadOption

                foreach ($headerName in $TestCase.ExpectedHeaders.Keys) {
                    $result[$headerName] | Should -Be $TestCase.ExpectedHeaders[$headerName] -Because $TestCase.Name
                }

                $result.Keys.Count | Should -Be $TestCase.ExpectedHeaders.Keys.Count -Because $TestCase.Name
            }
        }
    }

    It 'Resolve-NovaPackageUploadHeaders keeps token precedence explicit when <Name>' -ForEach @(
        @{
            Name = 'an explicit token overrides explicit and configured environment variables'
            UploadTarget = [pscustomobject]@{
                Headers = [ordered]@{}
                Auth = [ordered]@{
                    HeaderName = 'X-Api-Key'
                    TokenEnvironmentVariable = 'NOVA_PACKAGE_CONFIGURED_TOKEN'
                    Token = 'configured-literal-token'
                }
            }
            UploadOption = [pscustomobject]@{
                Headers = [ordered]@{}
                Token = 'explicit-token'
                TokenEnvironmentVariable = 'NOVA_PACKAGE_EXPLICIT_TOKEN'
                AuthenticationScheme = $null
            }
            Environment = @{
                NOVA_PACKAGE_CONFIGURED_TOKEN = 'configured-environment-token'
                NOVA_PACKAGE_EXPLICIT_TOKEN = 'explicit-environment-token'
            }
            ExpectedHeaderValue = 'explicit-token'
        }
        @{
            Name = 'an explicit token environment variable overrides configured auth values'
            UploadTarget = [pscustomobject]@{
                Headers = [ordered]@{}
                Auth = [ordered]@{
                    HeaderName = 'X-Api-Key'
                    TokenEnvironmentVariable = 'NOVA_PACKAGE_CONFIGURED_TOKEN'
                    Token = 'configured-literal-token'
                }
            }
            UploadOption = [pscustomobject]@{
                Headers = [ordered]@{}
                Token = $null
                TokenEnvironmentVariable = 'NOVA_PACKAGE_EXPLICIT_TOKEN'
                AuthenticationScheme = $null
            }
            Environment = @{
                NOVA_PACKAGE_CONFIGURED_TOKEN = 'configured-environment-token'
                NOVA_PACKAGE_EXPLICIT_TOKEN = 'explicit-environment-token'
            }
            ExpectedHeaderValue = 'explicit-environment-token'
        }
        @{
            Name = 'a configured token environment variable overrides a configured literal token'
            UploadTarget = [pscustomobject]@{
                Headers = [ordered]@{}
                Auth = [ordered]@{
                    HeaderName = 'X-Api-Key'
                    TokenEnvironmentVariable = 'NOVA_PACKAGE_CONFIGURED_TOKEN'
                    Token = 'configured-literal-token'
                }
            }
            UploadOption = [pscustomobject]@{
                Headers = [ordered]@{}
                Token = $null
                TokenEnvironmentVariable = $null
                AuthenticationScheme = $null
            }
            Environment = @{
                NOVA_PACKAGE_CONFIGURED_TOKEN = 'configured-environment-token'
                NOVA_PACKAGE_EXPLICIT_TOKEN = $null
            }
            ExpectedHeaderValue = 'configured-environment-token'
        }
    ) {
        $originalConfiguredToken = [System.Environment]::GetEnvironmentVariable('NOVA_PACKAGE_CONFIGURED_TOKEN')
        $originalExplicitToken = [System.Environment]::GetEnvironmentVariable('NOVA_PACKAGE_EXPLICIT_TOKEN')

        try {
            [System.Environment]::SetEnvironmentVariable('NOVA_PACKAGE_CONFIGURED_TOKEN', $_.Environment.NOVA_PACKAGE_CONFIGURED_TOKEN, 'Process')
            [System.Environment]::SetEnvironmentVariable('NOVA_PACKAGE_EXPLICIT_TOKEN', $_.Environment.NOVA_PACKAGE_EXPLICIT_TOKEN, 'Process')

            InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
                param($TestCase)

                $result = Resolve-NovaPackageUploadHeaders -UploadTarget $TestCase.UploadTarget -UploadOption $TestCase.UploadOption

                $result['X-Api-Key'] | Should -Be $TestCase.ExpectedHeaderValue
                $result.Keys.Count | Should -Be 1
            }
        }
        finally {
            [System.Environment]::SetEnvironmentVariable('NOVA_PACKAGE_CONFIGURED_TOKEN', $originalConfiguredToken, 'Process')
            [System.Environment]::SetEnvironmentVariable('NOVA_PACKAGE_EXPLICIT_TOKEN', $originalExplicitToken, 'Process')
        }
    }

    It 'Resolve-NovaPackageUploadTarget missing URL errors do not leak configured token values' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'missing-upload-url-secret-safe')
        $secretToken = 'do-not-log-this-token'

        InModuleScope $script:moduleName -Parameters @{
            SecretToken = $secretToken
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{
                Auth = [ordered]@{
                    Token = $secretToken
                }
            })
        } {
            param($ProjectInfo, $SecretToken)

            $thrown = $null

            try {
                Resolve-NovaPackageUploadTarget -ProjectInfo $ProjectInfo
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Not -Match [regex]::Escape($SecretToken)
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.PackageUploadTargetUrlMissing'
        }
    }

    It 'Deploy-NovaPackage uploads the specified package file to the specified raw URL' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'explicit-upload')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 201}}

            $result = @(Deploy-NovaPackage -PackagePath $PackagePath -Url 'https://packages.example/raw/')

            $result.Count | Should -Be 1
            $result[0].UploadUrl | Should -Be 'https://packages.example/raw/PackageProject.2.3.4.zip'
            $result[0].StatusCode | Should -Be 201
            Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
                $Uri -eq 'https://packages.example/raw/PackageProject.2.3.4.zip' -and
                        $Method -eq 'Put' -and
                        $InFile -eq $PackagePath
            }
        }
    }

    It 'Deploy-NovaPackage delegates orchestration to the private upload workflow helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaPackageUploadWorkflowContext {
                [pscustomobject]@{
                    Target = 'https://packages.example/raw/PackageProject.2.3.4.zip'
                    Operation = 'Upload Zip package artifact PackageProject.2.3.4.zip'
                    UploadArtifactList = @(
                        [pscustomobject]@{
                            Type = 'Zip'
                            PackagePath = '/tmp/project/artifacts/packages/PackageProject.2.3.4.zip'
                            PackageFileName = 'PackageProject.2.3.4.zip'
                            UploadUrl = 'https://packages.example/raw/PackageProject.2.3.4.zip'
                        }
                    )
                }
            }
            Mock Invoke-NovaPackageUploadWorkflow {
                @(
                    [pscustomobject]@{
                        PackageFileName = 'PackageProject.2.3.4.zip'
                        StatusCode = 200
                    }
                )
            }

            $result = @(Deploy-NovaPackage -Url 'https://packages.example/raw/' -Confirm:$false)

            $result.PackageFileName | Should -Be @('PackageProject.2.3.4.zip')
            $result.StatusCode | Should -Be @(200)
            Assert-MockCalled Get-NovaPackageUploadWorkflowContext -Times 1 -ParameterFilter {$BoundParameters.Url -eq 'https://packages.example/raw/'}
            Assert-MockCalled Invoke-NovaPackageUploadWorkflow -Times 1 -ParameterFilter {
                $WorkflowContext.UploadArtifactList.Count -eq 1 -and
                        $UploadArtifactList.Count -eq 1 -and
                        $UploadArtifactList[0].UploadUrl -eq 'https://packages.example/raw/PackageProject.2.3.4.zip'
            }
        }
    }

    It 'Deploy-NovaPackage keeps native PowerShell Confirm support for direct cmdlet usage' {
        InModuleScope $script:moduleName {
            $command = Get-Command -Name 'Deploy-NovaPackage' -CommandType Function -ErrorAction Stop

            $command.Parameters.ContainsKey('Confirm') | Should -BeTrue
            $command.Parameters.ContainsKey('WhatIf') | Should -BeTrue
        }
    }

    It 'Deploy-NovaPackage direct cmdlet usage does not route through the CLI confirmation helper' {
        InModuleScope $script:moduleName {
            Mock Confirm-NovaCliCommandAction {throw 'direct PowerShell deploy should not use the CLI confirmation helper'}
            Mock Get-NovaPackageUploadWorkflowContext {
                [pscustomobject]@{
                    Target = 'https://packages.example/raw/PackageProject.2.3.4.zip, https://packages.example/raw/PackageProject.latest.zip'
                    Operation = 'Upload 2 package artifacts'
                    UploadArtifactList = @(
                        [pscustomobject]@{
                            Type = 'Zip'
                            PackagePath = '/tmp/project/artifacts/packages/PackageProject.2.3.4.zip'
                            PackageFileName = 'PackageProject.2.3.4.zip'
                            UploadUrl = 'https://packages.example/raw/PackageProject.2.3.4.zip'
                        }
                        [pscustomobject]@{
                            Type = 'Zip'
                            PackagePath = '/tmp/project/artifacts/packages/PackageProject.latest.zip'
                            PackageFileName = 'PackageProject.latest.zip'
                            UploadUrl = 'https://packages.example/raw/PackageProject.latest.zip'
                        }
                    )
                }
            }
            Mock Invoke-NovaPackageUploadWorkflow {
                @(
                    [pscustomobject]@{PackageFileName = 'PackageProject.2.3.4.zip'; StatusCode = 200}
                    [pscustomobject]@{PackageFileName = 'PackageProject.latest.zip'; StatusCode = 200}
                )
            }

            $result = @(Deploy-NovaPackage -Url 'https://packages.example/raw/' -Confirm:$false)

            $result.PackageFileName | Should -Be @('PackageProject.2.3.4.zip', 'PackageProject.latest.zip')
            Assert-MockCalled Confirm-NovaCliCommandAction -Times 0
            Assert-MockCalled Invoke-NovaPackageUploadWorkflow -Times 1 -ParameterFilter {$UploadArtifactList.Count -eq 2}
        }
    }

    It 'Deploy-NovaPackage resolves the default package file from the package output directory when not explicitly provided' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'default-upload-file')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 200}}

            $result = @(Deploy-NovaPackage -Url 'https://packages.example/raw/')

            $result.PackagePath | Should -Be @($PackagePath)
            Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {$InFile -eq $PackagePath}
        }
    }

    It 'Deploy-NovaPackage resolves the target URL from project package repository settings when not explicitly provided' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'repository-upload-url')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'
        $repositoryList = @(
            [ordered]@{
                Name = 'LocalNexus'
                Url = 'https://packages.example/raw/com/acme/'
            }
        )

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{Repositories = $repositoryList})
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 200}}

            $result = @(Deploy-NovaPackage -Repository 'localnexus')

            $result[0].UploadUrl | Should -Be 'https://packages.example/raw/com/acme/PackageProject.2.3.4.zip'
            Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
                $Uri -eq 'https://packages.example/raw/com/acme/PackageProject.2.3.4.zip' -and
                        $InFile -eq $PackagePath
            }
        }
    }

    It 'Deploy-NovaPackage resolves matching artifacts when <Name>' -ForEach (Get-TestNovaPackageUploadArtifactResolutionCases) {
        $testCase = $_
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive $testCase.ProjectRootName)
        $artifactPathList = @(New-TestNovaPackageArtifactSet -Directory $layout.PackageOutputDir -PackageType @('NuGet', 'Zip') -IncludeLatest)
        $expectedPackagePathList = @(
        $artifactPathList |
                Where-Object {[System.IO.Path]::GetFileName($_) -like $testCase.ExpectedPackagePathFilter}
        )

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options $testCase.Options)
            ExpectedPackagePathList = $expectedPackagePathList
            ExpectedTypeList = $testCase.ExpectedTypeList
        } {
            param($ProjectInfo, $ExpectedPackagePathList, $ExpectedTypeList)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 200}}

            $result = @(Deploy-NovaPackage -Url 'https://packages.example/raw/')

            $result.Count | Should -Be $ExpectedPackagePathList.Count
            @($result.PackagePath | Sort-Object) | Should -Be @($ExpectedPackagePathList | Sort-Object)
            @($result.Type | Sort-Object) | Should -Be @($ExpectedTypeList | Sort-Object)
            Assert-MockCalled Invoke-WebRequest -Times $ExpectedPackagePathList.Count
        }
    }

    It 'Get-NovaPackageArtifactType exposes a structured validation error for unsupported file extensions' {
        InModuleScope $script:moduleName {
            $thrown = $null

            try {
                Get-NovaPackageArtifactType -PackagePath '/tmp/package.invalid'
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Unsupported package file extension for upload: /tmp/package.invalid*'
                ErrorId = 'Nova.Validation.UnsupportedPackageUploadFileType'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = '/tmp/package.invalid'
            })
        }
    }

    It 'Resolve-NovaPackageUploadOutputFileList exposes a structured error when the package output directory is missing' {
        $layout = [pscustomobject]@{
            ProjectRoot = (Join-Path $TestDrive 'missing-output-directory')
            PackageOutputDir = (Join-Path $TestDrive 'missing-output-directory/artifacts/packages')
        }

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
        } {
            param($ProjectInfo)

            $thrown = $null

            try {
                Resolve-NovaPackageUploadOutputFileList -ProjectInfo $ProjectInfo
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = "Package output directory not found: $( $ProjectInfo.Package.OutputDirectory.Path )*"
                ErrorId = 'Nova.Environment.PackageOutputDirectoryNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = $ProjectInfo.Package.OutputDirectory.Path
            })
        }
    }

    It 'Resolve-NovaPackageUploadOutputFileSet exposes a structured workflow error when a requested artifact type is missing' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'missing-output-artifact')
        New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip' | Out-Null

        InModuleScope $script:moduleName -Parameters @{
            OutputDirectory = $layout.PackageOutputDir
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{PackageTypes = @('Zip', 'NuGet')})
        } {
            param($OutputDirectory, $ProjectInfo)

            $thrown = $null

            try {
                Resolve-NovaPackageUploadOutputFileSet -OutputDirectory $OutputDirectory -ProjectInfo $ProjectInfo -PackageType 'NuGet'
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = "Package file not found for package type 'NuGet' in '$OutputDirectory'*"
                ErrorId = 'Nova.Workflow.PackageOutputArtifactNotFound'
                Category = [System.Management.Automation.ErrorCategory]::InvalidOperation
                TargetObject = 'NuGet'
            })
        }
    }

    It 'Deploy-NovaPackage fails clearly when PackageType conflicts with FileNamePattern' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'conflicting-package-type-and-pattern')
        New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip' | Out-Null

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{PackageTypes = @('Zip', 'NuGet'); FileNamePattern = 'PackageProject.*.zip'})
        } {
            param($ProjectInfo)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            $conflictError = $null
            try {
                Deploy-NovaPackage -PackageType NuGet -Url 'https://packages.example/raw/'
            }
            catch {
                $conflictError = $_
            }

            Assert-TestStructuredError -ThrownError $conflictError -ExpectedError ([pscustomobject]@{
                Message = "Package.FileNamePattern 'PackageProject.*.zip' resolves to type 'Zip'*"
                ErrorId = 'Nova.Validation.PackageUploadPatternConflict'
                Category = [System.Management.Automation.ErrorCategory]::InvalidArgument
                TargetObject = 'PackageProject.*.zip'
            })
        }
    }

    It 'Deploy-NovaPackage fails with a clear message when the package file is missing' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'missing-package-file')

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
        } {
            param($ProjectInfo)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            $missingPath = Join-Path $ProjectInfo.ProjectRoot 'missing.zip'
            $missingPackageError = $null
            try {
                Deploy-NovaPackage -PackagePath $missingPath -Url 'https://packages.example/raw/'
            }
            catch {
                $missingPackageError = $_
            }

            Assert-TestStructuredError -ThrownError $missingPackageError -ExpectedError ([pscustomobject]@{
                Message = 'Package file not found:*'
                ErrorId = 'Nova.Environment.PackageUploadFileNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = $missingPath
            })
        }
    }

    It 'Deploy-NovaPackage fails with a clear message when <Name>' -ForEach (Get-TestNovaPackageUploadFailureCases) {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive $_.ProjectRootName)
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
            ExpectedError = $_.ExpectedError
            InvokeAction = $_.Invoke
        } {
            param($ProjectInfo, $PackagePath, $ExpectedError, $InvokeAction)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            $thrown = $null
            try {
                & $InvokeAction $PackagePath
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError $ExpectedError
        }
    }

    It 'Get-NovaPackageRepository exposes a structured configuration error when a named repository cannot be resolved' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'missing-package-repository')

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
        } {
            param($ProjectInfo)

            $thrown = $null
            try {
                Get-NovaPackageRepository -ProjectInfo $ProjectInfo -Repository 'MissingRepo'
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Package repository not found: MissingRepo*'
                ErrorId = 'Nova.Configuration.PackageRepositoryNotFound'
                Category = [System.Management.Automation.ErrorCategory]::InvalidData
                TargetObject = 'MissingRepo'
            })
        }
    }

    It 'Invoke-NovaPackageArtifactUpload exposes a structured error when the package file is missing' {
        InModuleScope $script:moduleName {
            $uploadArtifact = [pscustomobject]@{
                Type = 'Zip'
                PackagePath = '/tmp/missing-package.zip'
                PackageFileName = 'missing-package.zip'
                Repository = ''
                UploadUrl = 'https://packages.example/raw/missing-package.zip'
                Headers = [ordered]@{}
            }

            $thrown = $null
            try {
                Invoke-NovaPackageArtifactUpload -UploadArtifact $uploadArtifact
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = 'Package file not found: /tmp/missing-package.zip'
                ErrorId = 'Nova.Environment.PackageUploadFileNotFound'
                Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
                TargetObject = '/tmp/missing-package.zip'
            })
        }
    }

    It 'Invoke-NovaPackageArtifactUpload delegates request execution to the upload adapter' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'upload-request-adapter')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{PackagePath = $packagePath} {
            param($PackagePath)

            $uploadArtifact = [pscustomobject]@{
                Type = 'Zip'
                PackagePath = $PackagePath
                PackageFileName = 'PackageProject.2.3.4.zip'
                Repository = 'LocalRaw'
                UploadUrl = 'https://packages.example/raw/PackageProject.2.3.4.zip'
                Headers = [ordered]@{'X-Trace-Id' = 'trace-123'}
            }

            Mock Invoke-NovaPackageUploadRequest {
                [pscustomobject]@{StatusCode = 202}
            }

            $result = Invoke-NovaPackageArtifactUpload -UploadArtifact $uploadArtifact

            $result.StatusCode | Should -Be 202
            Assert-MockCalled Invoke-NovaPackageUploadRequest -Times 1 -ParameterFilter {
                $UploadArtifact.PackagePath -eq $PackagePath -and
                        $UploadArtifact.Headers['X-Trace-Id'] -eq 'trace-123'
            }
        }
    }

    It 'Invoke-NovaPackageArtifactUpload exposes a structured dependency error when the upload request fails' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'upload-request-fails')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{PackagePath = $packagePath} {
            param($PackagePath)

            $uploadArtifact = [pscustomobject]@{
                Type = 'Zip'
                PackagePath = $PackagePath
                PackageFileName = 'PackageProject.2.3.4.zip'
                Repository = ''
                UploadUrl = 'https://packages.example/raw/PackageProject.2.3.4.zip'
                Headers = [ordered]@{}
            }

            Mock Invoke-NovaPackageUploadRequest {throw 'network down'}

            $thrown = $null
            try {
                Invoke-NovaPackageArtifactUpload -UploadArtifact $uploadArtifact
            }
            catch {
                $thrown = $_
            }

            Assert-TestStructuredError -ThrownError $thrown -ExpectedError ([pscustomobject]@{
                Message = "Package upload failed for $PackagePath -> https://packages.example/raw/PackageProject.2.3.4.zip*"
                ErrorId = 'Nova.Dependency.PackageUploadRequestFailed'
                Category = [System.Management.Automation.ErrorCategory]::ConnectionError
                TargetObject = 'https://packages.example/raw/PackageProject.2.3.4.zip'
            })
        }
    }

    It 'Deploy-NovaPackage includes expected headers and auth when configured' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'upload-headers-and-auth')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'
        $repositoryList = @(
            [ordered]@{
                Name = 'RawRepo'
                Url = 'https://packages.example/raw/'
                Auth = [ordered]@{
                    HeaderName = 'X-Api-Key'
                    TokenEnvironmentVariable = 'NOVA_PACKAGE_UPLOAD_TOKEN'
                }
            }
        )
        $originalToken = [System.Environment]::GetEnvironmentVariable('NOVA_PACKAGE_UPLOAD_TOKEN')
        [System.Environment]::SetEnvironmentVariable('NOVA_PACKAGE_UPLOAD_TOKEN', 'secret-token', 'Process')

        try {
            InModuleScope $script:moduleName -Parameters @{
                ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{Repositories = $repositoryList; Headers = [ordered]@{'X-Trace-Id' = 'trace-123'}})
                PackagePath = $packagePath
            } {
                param($ProjectInfo, $PackagePath)

                Mock Get-NovaProjectInfo {$ProjectInfo}
                Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 200}}

                $result = @(Deploy-NovaPackage -Repository RawRepo)

                $result.Count | Should -Be 1
                Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
                    $Headers['X-Trace-Id'] -eq 'trace-123' -and
                            $Headers['X-Api-Key'] -eq 'secret-token' -and
                            $InFile -eq $PackagePath
                }
            }
        }
        finally {
            [System.Environment]::SetEnvironmentVariable('NOVA_PACKAGE_UPLOAD_TOKEN', $originalToken, 'Process')
        }
    }

    It 'Deploy-NovaPackage supports WhatIf and does not upload when previewing' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'upload-whatif')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {throw 'should not upload during WhatIf'}

            $result = Deploy-NovaPackage -PackagePath $PackagePath -Url 'https://packages.example/raw/' -WhatIf

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Invoke-WebRequest -Times 0
        }
    }

    It 'Publish-NovaModule repository behavior remains unchanged and does not route through Deploy-NovaPackage' {
        InModuleScope $script:moduleName {
            $publishAction = {
                param($ProjectInfo, $Repository, $ApiKey)

                Publish-NovaBuiltModuleToRepository @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Resolve-NovaPublishInvocation {
                [pscustomobject]@{
                    Target = 'PSGallery'
                    IsLocal = $false
                    Action = $publishAction
                }
            }
            Mock Write-NovaLocalWorkflowMode {}
            Mock Write-NovaResolvedLocalPublishTarget {}
            Mock Get-NovaPublishWorkflowOperation {'Publish built module to repository'}
            Mock Get-NovaLocalPublishActivation {$null}
            Mock Get-NovaResolvedPublishParameterMap {
                @{
                    ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist/NovaModuleTools'}
                    Repository = 'PSGallery'
                    ApiKey = 'key123'
                }
            }
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Deploy-NovaPackage {throw 'should not upload'}

            {Publish-NovaModule -Repository PSGallery -ApiKey key123 -Confirm:$false} | Should -Not -Throw

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'key123'}
            Assert-MockCalled Deploy-NovaPackage -Times 0
        }
    }
}
