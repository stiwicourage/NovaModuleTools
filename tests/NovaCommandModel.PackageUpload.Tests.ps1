$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
$script:packageUploadTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.PackageUpload.TestSupport.ps1')).Path
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
. $script:packageUploadTestSupportPath

foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}
foreach ($functionName in $global:novaCommandModelPackageUploadTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

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

    It 'Deploy-NovaPackage resolves matching artifacts when <Name>' -ForEach @(
        @{
            Name = 'multiple artifacts exist for the configured package types'
            ProjectRootName = 'multi-artifact-upload'
            Options = @{PackageTypes = @('Zip', 'NuGet')}
            ExpectedPackagePathFilter = 'PackageProject.*'
            ExpectedTypeList = @('NuGet', 'NuGet', 'Zip', 'Zip')
        }
        @{
            Name = 'FileNamePattern targets zip artifacts'
            ProjectRootName = 'explicit-zip-pattern-upload'
            Options = @{PackageTypes = @('Zip', 'NuGet'); FileNamePattern = 'PackageProject.*.zip'}
            ExpectedPackagePathFilter = '*.zip'
            ExpectedTypeList = @('Zip', 'Zip')
        }
    ) {
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

    It 'Deploy-NovaPackage fails clearly when PackageType conflicts with FileNamePattern' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'conflicting-package-type-and-pattern')
        New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip' | Out-Null

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{PackageTypes = @('Zip', 'NuGet'); FileNamePattern = 'PackageProject.*.zip'})
        } {
            param($ProjectInfo)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            {Deploy-NovaPackage -PackageType NuGet -Url 'https://packages.example/raw/'} | Should -Throw "Package.FileNamePattern 'PackageProject.*.zip' resolves to type 'Zip'*"
        }
    }

    It 'Deploy-NovaPackage fails with a clear message when the package file is missing' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'missing-package-file')

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
        } {
            param($ProjectInfo)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            {Deploy-NovaPackage -PackagePath (Join-Path $ProjectInfo.ProjectRoot 'missing.zip') -Url 'https://packages.example/raw/'} | Should -Throw 'Package file not found:*'
        }
    }

    It 'Deploy-NovaPackage fails with a clear message when <Name>' -ForEach @(
        @{
            Name = 'the upload target URL is missing'
            ProjectRootName = 'missing-upload-url'
            ExpectedMessage = 'Upload target URL is missing*'
            Invoke = {
                param($PackagePath)

                Deploy-NovaPackage -PackagePath $PackagePath
            }
        }
        @{
            Name = 'package selection is ambiguous'
            ProjectRootName = 'ambiguous-package-selection'
            ExpectedMessage = 'Package selection is ambiguous*'
            Invoke = {
                param($PackagePath)

                Deploy-NovaPackage -PackagePath $PackagePath -PackageType NuGet -Url 'https://packages.example/raw/'
            }
        }
    ) {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive $_.ProjectRootName)
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
            ExpectedMessage = $_.ExpectedMessage
            InvokeAction = $_.Invoke
        } {
            param($ProjectInfo, $PackagePath, $ExpectedMessage, $InvokeAction)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            {& $InvokeAction $PackagePath} | Should -Throw $ExpectedMessage
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
