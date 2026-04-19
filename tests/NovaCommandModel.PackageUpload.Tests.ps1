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
    It 'Upload-NovaPackage uploads the specified package file to the specified raw URL' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'explicit-upload')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 201}}

            $result = @(Upload-NovaPackage -PackagePath $PackagePath -Url 'https://packages.example/raw/')

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

    It 'Upload-NovaPackage resolves the default package file from the package output directory when not explicitly provided' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'default-upload-file')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 200}}

            $result = @(Upload-NovaPackage -Url 'https://packages.example/raw/')

            $result.PackagePath | Should -Be @($PackagePath)
            Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {$InFile -eq $PackagePath}
        }
    }

    It 'Upload-NovaPackage resolves the target URL from project package repository settings when not explicitly provided' {
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

            $result = @(Upload-NovaPackage -Repository 'localnexus')

            $result[0].UploadUrl | Should -Be 'https://packages.example/raw/com/acme/PackageProject.2.3.4.zip'
            Assert-MockCalled Invoke-WebRequest -Times 1 -ParameterFilter {
                $Uri -eq 'https://packages.example/raw/com/acme/PackageProject.2.3.4.zip' -and
                        $InFile -eq $PackagePath
            }
        }
    }

    It 'Upload-NovaPackage handles the current package model when multiple artifacts may exist' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'multi-artifact-upload')
        $expectedPackagePathList = @(
            New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.nupkg'
            New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.latest.nupkg'
            New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'
            New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.latest.zip'
        )

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout -Options @{PackageTypes = @('Zip', 'NuGet')})
            ExpectedPackagePathList = $expectedPackagePathList
        } {
            param($ProjectInfo, $ExpectedPackagePathList)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {[pscustomobject]@{StatusCode = 200}}

            $result = @(Upload-NovaPackage -Url 'https://packages.example/raw/')

            $result.Count | Should -Be 4
            @($result.PackagePath | Sort-Object) | Should -Be @($ExpectedPackagePathList | Sort-Object)
            @($result.Type | Sort-Object) | Should -Be @('NuGet', 'NuGet', 'Zip', 'Zip')
            Assert-MockCalled Invoke-WebRequest -Times 4
        }
    }

    It 'Upload-NovaPackage fails with a clear message when the package file is missing' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'missing-package-file')

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
        } {
            param($ProjectInfo)

            Mock Get-NovaProjectInfo {$ProjectInfo}

            {Upload-NovaPackage -PackagePath (Join-Path $ProjectInfo.ProjectRoot 'missing.zip') -Url 'https://packages.example/raw/'} | Should -Throw 'Package file not found:*'
        }
    }

    It 'Upload-NovaPackage fails with a clear message when <Name>' -ForEach @(
        @{
            Name = 'the upload target URL is missing'
            ProjectRootName = 'missing-upload-url'
            ExpectedMessage = 'Upload target URL is missing*'
            Invoke = {
                param($PackagePath)

                Upload-NovaPackage -PackagePath $PackagePath
            }
        }
        @{
            Name = 'package selection is ambiguous'
            ProjectRootName = 'ambiguous-package-selection'
            ExpectedMessage = 'Package selection is ambiguous*'
            Invoke = {
                param($PackagePath)

                Upload-NovaPackage -PackagePath $PackagePath -PackageType NuGet -Url 'https://packages.example/raw/'
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

    It 'Upload-NovaPackage includes expected headers and auth when configured' {
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

                $result = @(Upload-NovaPackage -Repository RawRepo)

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

    It 'Upload-NovaPackage supports WhatIf and does not upload when previewing' {
        $layout = Initialize-TestNovaPackageUploadLayout -ProjectRoot (Join-Path $TestDrive 'upload-whatif')
        $packagePath = New-TestNovaPackageArtifactFile -Directory $layout.PackageOutputDir -Name 'PackageProject.2.3.4.zip'

        InModuleScope $script:moduleName -Parameters @{
            ProjectInfo = (New-TestNovaPackageUploadProjectInfo -Layout $layout)
            PackagePath = $packagePath
        } {
            param($ProjectInfo, $PackagePath)

            Mock Get-NovaProjectInfo {$ProjectInfo}
            Mock Invoke-WebRequest {throw 'should not upload during WhatIf'}

            $result = Upload-NovaPackage -PackagePath $PackagePath -Url 'https://packages.example/raw/' -WhatIf

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Invoke-WebRequest -Times 0
        }
    }

    It 'Publish-NovaModule repository behavior remains unchanged and does not route through Upload-NovaPackage' {
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
            Mock Upload-NovaPackage {throw 'should not upload'}

            {Publish-NovaModule -Repository PSGallery -ApiKey key123 -Confirm:$false} | Should -Not -Throw

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'key123'}
            Assert-MockCalled Upload-NovaPackage -Times 0
        }
    }
}

