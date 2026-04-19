$script:testSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'NovaCommandModel.TestSupport.ps1')).Path
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

foreach ($functionName in $global:novaCommandModelTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

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
}

Describe 'Nova command model - release and publish behavior' {
    It 'Invoke-NovaRelease runs build test bump build publish in order' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Update-NovaModuleVersion {
                $script:steps += 'bump'
                return [pscustomobject]@{NewVersion = '1.0.1'}
            }
            Mock Test-Path {$true}
            Mock Remove-Item {}
            Mock Copy-Item {$script:steps += 'publish'}

            Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path | Out-Null

            $script:steps -join ',' | Should -Be 'build,test,bump,build,publish'
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

            {Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path} | Should -Throw
            Assert-MockCalled Update-NovaModuleVersion -Times 0
        }
    }

    It 'Invoke-NovaRelease -WhatIf forwards preview mode through the nested workflow' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $publishAction = {
                param($ProjectInfo, $ModuleDirectoryPath)

                Publish-NovaBuiltModuleToDirectory @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $publishAction}
            } -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToDirectory' -and $CommandType -eq 'Function'}
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock Update-NovaModuleVersion {
                $script:steps += "bump:$WhatIfPreference"
                [pscustomobject]@{PreviousVersion = '1.0.0'; NewVersion = '1.0.0'; Label = 'Patch'; CommitCount = 0}
            }
            Mock Publish-NovaBuiltModuleToDirectory {$script:steps += "publish:$WhatIfPreference"}

            $result = Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path -WhatIf

            $script:steps -join ',' | Should -Be 'build:True,test:True,bump:True,build:True,publish:True'
            $result.NewVersion | Should -Be '1.0.0'
        }
    }

    It 'Invoke-NovaRelease reuses shared publish parameter resolution for local release execution' {
        InModuleScope $script:moduleName {
            $script:publishBoundParameters = $null

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Write-NovaLocalWorkflowMode {}
            Mock Write-NovaResolvedLocalPublishTarget {}
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
                }
            }
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Update-NovaModuleVersion {
                [pscustomobject]@{NewVersion = '1.0.1'}
            }
            Mock Import-NovaPublishedLocalModule {throw 'release should not import the published module'}

            {Invoke-NovaRelease -PublishOption @{Local = $true} -Path (Get-Location).Path} | Should -Not -Throw

            Assert-MockCalled Get-NovaResolvedPublishParameterMap -Times 1
            Assert-MockCalled Write-NovaResolvedLocalPublishTarget -Times 1 -ParameterFilter {$PublishInvocation.IsLocal}
            $script:publishBoundParameters.ProjectInfo.ProjectName | Should -Be 'NovaModuleTools'
            $script:publishBoundParameters.ModuleDirectoryPath | Should -Be '/tmp/modules'
            @($script:publishBoundParameters.Keys | Sort-Object) | Should -Be @('ModuleDirectoryPath', 'ProjectInfo')
        }
    }

    It 'Publish-NovaModule resolves the local target and published manifest before testing, then imports the published module from that local path' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $localManifestPath = '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
            $importAction = {
                param($ProjectName, $ManifestPath)

                Import-NovaPublishedLocalModule @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-LocalModulePath {
                $script:steps += 'resolve'
                '/tmp/modules'
            }
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $importAction}
            } -ParameterFilter {$Name -eq 'Import-NovaPublishedLocalModule' -and $CommandType -eq 'Function'}
            Mock Get-NovaPublishedLocalManifestPath {
                $script:steps += 'manifest'
                $localManifestPath
            }
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {
                $script:steps += 'test'
                Remove-Item function:Get-LocalModulePath -ErrorAction SilentlyContinue
            }
            Mock Test-Path {$true}
            Mock Remove-Item {}
            Mock Copy-Item {$script:steps += 'copy'}
            Mock Import-NovaPublishedLocalModule {$script:steps += 'import'}

            {Publish-NovaModule -Local} | Should -Not -Throw

            $script:steps -join ',' | Should -Be 'resolve,manifest,build,test,copy,import'
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Destination -eq '/tmp/modules'}
            Assert-MockCalled Import-NovaPublishedLocalModule -Times 1 -ParameterFilter {$ProjectName -eq 'NovaModuleTools' -and $ManifestPath -eq $localManifestPath}
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

    It 'Publish-NovaModule -WhatIf forwards preview mode to build, test, and publish helpers' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $publishAction = {
                param($ProjectInfo, $ModuleDirectoryPath)

                Publish-NovaBuiltModuleToDirectory @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $publishAction}
            } -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToDirectory' -and $CommandType -eq 'Function'}
            Mock Get-LocalModulePath {'/tmp/modules'}
            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock Publish-NovaBuiltModuleToDirectory {$script:steps += "publish:$WhatIfPreference"}
            Mock Import-NovaPublishedLocalModule {$script:steps += 'import'}

            $result = Publish-NovaModule -Local -WhatIf

            $result | Should -BeNullOrEmpty
            $script:steps -join ',' | Should -Be 'build:True,test:True,publish:True'
            Assert-MockCalled Import-NovaPublishedLocalModule -Times 0
        }
    }

    It 'Publish-NovaModule repository mode does not import the published module after publish' {
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
            Mock Get-Command {
                [pscustomobject]@{ScriptBlock = $publishAction}
            } -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToRepository' -and $CommandType -eq 'Function'}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Import-NovaPublishedLocalModule {}

            {Publish-NovaModule -Repository PSGallery -ApiKey key123} | Should -Not -Throw

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'key123'}
            Assert-MockCalled Import-NovaPublishedLocalModule -Times 0
        }
    }

    It 'Pack-NovaModule runs build, test, and package creation in order' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    Version = '1.2.3'
                    ProjectRoot = '/tmp/project'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    Description = 'Package test'
                    Manifest = [ordered]@{
                        Author = 'Test Author'
                        Tags = @('Nova', 'PowerShell')
                        ProjectUri = 'https://example.test/project'
                        ReleaseNotes = 'https://example.test/release-notes'
                        LicenseUri = 'https://example.test/license'
                    }
                    Package = [ordered]@{
                        Enabled = $true
                        Id = 'NovaModuleTools'
                        OutputDirectory = '/tmp/project/artifacts/packages'
                        PackageFileName = 'NovaModuleTools.1.2.3.nupkg'
                        Authors = 'Test Author'
                        Description = 'Package test'
                    }
                }
            }
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock New-NovaPackageArtifact {
                $script:steps += 'pack'
                [pscustomobject]@{PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
            }

            $result = Pack-NovaModule

            $script:steps -join ',' | Should -Be 'build,test,pack'
            $result.PackagePath | Should -Be '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'
        }
    }

    It 'Pack-NovaModule reimports the current module when package helpers were unloaded during tests' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    Version = '1.2.3'
                    ProjectRoot = '/tmp/project'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    Description = 'Package test'
                    Manifest = [ordered]@{
                        Author = 'Test Author'
                        Tags = @('Nova', 'PowerShell')
                        ProjectUri = 'https://example.test/project'
                        ReleaseNotes = 'https://example.test/release-notes'
                        LicenseUri = 'https://example.test/license'
                    }
                    Package = [ordered]@{
                        Enabled = $true
                        Id = 'NovaModuleTools'
                        OutputDirectory = '/tmp/project/artifacts/packages'
                        PackageFileName = 'NovaModuleTools.1.2.3.nupkg'
                        Authors = 'Test Author'
                        Description = 'Package test'
                    }
                }
            }
            Mock Invoke-NovaBuild {$script:steps += 'build'}
            Mock Test-NovaBuild {$script:steps += 'test'}
            Mock Get-Command {
                $null
            } -ParameterFilter {$Name -eq 'New-NovaPackageArtifact' -and $CommandType -eq 'Function'}
            Mock Import-Module {
                $ExecutionContext.SessionState.Module
            } -ParameterFilter {$Name -eq $ExecutionContext.SessionState.Module.Path -and $PassThru}
            Mock New-NovaPackageArtifact {
                $script:steps += 'pack'
                [pscustomobject]@{PackagePath = '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'}
            }

            $result = Pack-NovaModule

            $script:steps -join ',' | Should -Be 'build,test,pack'
            $result.PackagePath | Should -Be '/tmp/project/artifacts/packages/NovaModuleTools.1.2.3.nupkg'
            Assert-MockCalled Import-Module -Times 1 -ParameterFilter {$Name -eq $ExecutionContext.SessionState.Module.Path -and $PassThru}
        }
    }

    It 'Pack-NovaModule -WhatIf forwards preview mode through build and test without creating a package' {
        InModuleScope $script:moduleName {
            $script:steps = @()

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    Version = '1.2.3'
                    ProjectRoot = '/tmp/project'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    Description = 'Package test'
                    Manifest = [ordered]@{
                        Author = 'Test Author'
                        Tags = @()
                        ProjectUri = ''
                        ReleaseNotes = ''
                        LicenseUri = ''
                    }
                    Package = [ordered]@{
                        Enabled = $true
                        Id = 'NovaModuleTools'
                        OutputDirectory = '/tmp/project/artifacts/packages'
                        PackageFileName = 'NovaModuleTools.1.2.3.nupkg'
                        Authors = 'Test Author'
                        Description = 'Package test'
                    }
                }
            }
            Mock Invoke-NovaBuild {$script:steps += "build:$WhatIfPreference"}
            Mock Test-NovaBuild {$script:steps += "test:$WhatIfPreference"}
            Mock New-NovaPackageArtifact {$script:steps += 'pack'}

            $result = Pack-NovaModule -WhatIf

            $result | Should -BeNullOrEmpty
            $script:steps -join ',' | Should -Be 'build:True,test:True'
            Assert-MockCalled New-NovaPackageArtifact -Times 0
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
                    Enabled = $true
                    Id = 'PackageProject'
                    OutputDirectory = '/tmp/project/artifacts/packages'
                    PackageFileName = 'PackageProject.2.3.4.nupkg'
                    Authors = 'Author One'
                    Description = 'Top-level description'
                }
            }

            $result = Get-NovaPackageMetadata -ProjectInfo $projectInfo

            $result.Id | Should -Be 'PackageProject'
            $result.Version | Should -Be '2.3.4'
            $result.Authors | Should -Be @('Author One')
            $result.Description | Should -Be 'Top-level description'
            $result.Tags | Should -Be @('Nova', 'Packaging')
            $result.ProjectUrl | Should -Be 'https://example.test/project'
            $result.ReleaseNotes | Should -Be 'https://example.test/release-notes'
            $result.LicenseUrl | Should -Be 'https://example.test/license'
            $result.OutputDirectory | Should -Be '/tmp/project/artifacts/packages'
            $result.PackagePath | Should -Be '/tmp/project/artifacts/packages/PackageProject.2.3.4.nupkg'
        }
    }

    It 'Pack-NovaModule fails with a clear message when package metadata is missing' {
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
                        Enabled = $true
                        Id = 'NovaModuleTools'
                        OutputDirectory = '/tmp/project/artifacts/packages'
                        PackageFileName = 'NovaModuleTools.1.2.3.nupkg'
                        Authors = @()
                        Description = 'Package test'
                    }
                }
            }
            Mock Invoke-NovaBuild {throw 'should not build'}
            Mock Test-NovaBuild {throw 'should not test'}

            {Pack-NovaModule} | Should -Throw 'Missing package metadata value: Authors'
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

            $expectedError = if ($IsWindows) {
                'No windows module path matching*'
            }
            else {
                'No macOS/Linux module path matching*'
            }

            try {
                {Get-LocalModulePath} | Should -Throw $expectedError
            }
            finally {
                $env:PSModulePath = $originalModulePath
            }
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

        $publishSource.IndexOf('Resolve-NovaPublishInvocation') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Invoke-NovaBuild') | Should -BeGreaterThan -1
        $publishSource.IndexOf('Resolve-NovaPublishInvocation') | Should -BeLessThan $publishSource.IndexOf('Invoke-NovaBuild')
    }
}




