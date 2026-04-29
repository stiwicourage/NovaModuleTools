$script:gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
$global:gitTestSupportFunctionNameList = @(
    'Initialize-TestGitRepository'
    'New-TestGitCommit'
    'New-TestGitTag'
)
. $script:gitTestSupportPath

foreach ($functionName in $global:gitTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $gitTestSupportPath
    foreach ($functionName in $global:gitTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage gaps for release and git internals' {
    It 'Get-VersionLabelFromCommitSet classifies major, minor, and patch releases' {
        InModuleScope $script:moduleName {
            Get-VersionLabelFromCommitSet -Messages @('feat!: breaking api') | Should -Be 'Major'
            Get-VersionLabelFromCommitSet -Messages @('BREAKING CHANGE: api') | Should -Be 'Major'
            Get-VersionLabelFromCommitSet -Messages @('feat: add capability') | Should -Be 'Minor'
            Get-VersionLabelFromCommitSet -Messages @('fix: patch bug') | Should -Be 'Patch'
            Get-VersionLabelFromCommitSet -Messages @('docs: update readme') | Should -Be 'Patch'
        }
    }

    It 'Get-NovaVersionPartForLabel returns the next semantic version parts' {
        InModuleScope $script:moduleName {
            $major = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Major
            $minor = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Minor
            $patch = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Patch

            "$( $major.Major ).$( $major.Minor ).$( $major.Patch )" | Should -Be '2.0.0'
            "$( $minor.Major ).$( $minor.Minor ).$( $minor.Patch )" | Should -Be '1.3.0'
            "$( $patch.Major ).$( $patch.Minor ).$( $patch.Patch )" | Should -Be '1.2.4'
        }
    }

    It 'Get-NovaVersionPartForLabel finalizes prerelease targets or advances to the next stable core when <Name>' -ForEach @(
        @{Name = 'major prerelease already targets the current release line'; CurrentVersion = '2.0.0-preview7'; Label = 'Major'; Expected = '2.0.0'}
        @{Name = 'minor prerelease already targets the current release line'; CurrentVersion = '1.3.0-preview7'; Label = 'Minor'; Expected = '1.3.0'}
        @{Name = 'patch prerelease already targets the current release line'; CurrentVersion = '1.2.4-preview7'; Label = 'Patch'; Expected = '1.2.4'}
        @{Name = 'major prerelease on a lower release line advances to the next major'; CurrentVersion = '1.2.3-preview7'; Label = 'Major'; Expected = '2.0.0'}
        @{Name = 'minor prerelease on a lower release line advances to the next minor'; CurrentVersion = '1.2.3-preview7'; Label = 'Minor'; Expected = '1.3.0'}
        @{Name = 'patch prerelease on the current patch line finalizes that line'; CurrentVersion = '1.2.3-preview7'; Label = 'Patch'; Expected = '1.2.3'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            $result = Get-NovaVersionPartForLabel -CurrentVersion ([semver]$TestCase.CurrentVersion) -Label $TestCase.Label

            "$( $result.Major ).$( $result.Minor ).$( $result.Patch )" | Should -Be $TestCase.Expected
        }
    }

    It 'Get-NovaVersionPreReleaseLabel returns preview or stable output without preserving prerelease labels by default' {
        InModuleScope $script:moduleName {
            Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3') -PreviewRelease | Should -Be 'preview'
            $stable = Get-NovaVersionPreReleaseLabel -StableRelease
            $stable | Should -BeNullOrEmpty
            Get-NovaVersionPreReleaseLabel | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaVersionPreReleaseLabel increments existing prerelease labels generically when preview mode is requested' -ForEach @(
        @{CurrentVersion = '1.2.3-preview'; Expected = 'preview01'}
        @{CurrentVersion = '1.2.3-preview01'; Expected = 'preview02'}
        @{CurrentVersion = '1.2.3-preview09'; Expected = 'preview10'}
        @{CurrentVersion = '1.2.3-preview1'; Expected = 'preview2'}
        @{CurrentVersion = '1.2.3-preview9'; Expected = 'preview10'}
        @{CurrentVersion = '1.2.3-preview.7'; Expected = 'preview.8'}
        @{CurrentVersion = '1.2.3-rc1'; Expected = 'rc2'}
        @{CurrentVersion = '1.2.3-SNAPSHOT'; Expected = 'SNAPSHOT01'}
        @{CurrentVersion = '1.2.3-SNAPSHOT1'; Expected = 'SNAPSHOT2'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]$TestCase.CurrentVersion) -PreviewRelease | Should -Be $TestCase.Expected
        }
    }

    It 'Get-NovaVersionPreReleaseLabel handles dotted prerelease identifiers when preview parsing is supported' {
        InModuleScope $script:moduleName {
            $version = [semver]'1.2.3-preview.7'

            $version.ToString() | Should -Be '1.2.3-preview.7'
            Get-NovaVersionPreReleaseLabel -PreviewRelease | Should -Be 'preview'
            Get-NovaVersionPreReleaseLabel | Should -BeNullOrEmpty
        }
    }

    It 'Get-NovaVersionUpdatePlan resolves prerelease versions to the expected next stable target when <Name>' -ForEach @(
        @{Name = 'finalizing a major prerelease line'; CurrentVersion = '2.0.0-preview7'; Label = 'Major'; ExpectedVersion = '2.0.0'}
        @{Name = 'finalizing a minor prerelease line'; CurrentVersion = '1.3.0-preview7'; Label = 'Minor'; ExpectedVersion = '1.3.0'}
        @{Name = 'finalizing a patch prerelease line'; CurrentVersion = '1.2.4-preview7'; Label = 'Patch'; ExpectedVersion = '1.2.4'}
        @{Name = 'advancing from an earlier prerelease line to the next minor'; CurrentVersion = '1.2.3-preview7'; Label = 'Minor'; ExpectedVersion = '1.3.0'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectJSON = '/tmp/project.json'
                    Version = $TestCase.CurrentVersion
                }
            }

            (Get-NovaVersionUpdatePlan -Label $TestCase.Label).NewVersion.ToString() | Should -Be $TestCase.ExpectedVersion
        }
    }

    It 'Get-NovaVersionUpdatePlan appends a preview label to the normal bump target when preview mode starts from stable' -ForEach @(
        @{CurrentVersion = '1.5.3'; Label = 'Major'; ExpectedVersion = '2.0.0-preview'}
        @{CurrentVersion = '1.5.3'; Label = 'Minor'; ExpectedVersion = '1.6.0-preview'}
        @{CurrentVersion = '1.5.3'; Label = 'Patch'; ExpectedVersion = '1.5.4-preview'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectJSON = '/tmp/project.json'
                    Version = $TestCase.CurrentVersion
                }
            }

            (Get-NovaVersionUpdatePlan -Label $TestCase.Label -PreviewRelease).NewVersion.ToString() | Should -Be $TestCase.ExpectedVersion
        }
    }

    It 'Get-NovaVersionUpdatePlan keeps the semantic core and increments an existing prerelease label when preview mode continues a prerelease' -ForEach @(
        @{CurrentVersion = '1.5.3-preview'; ExpectedVersion = '1.5.3-preview01'}
        @{CurrentVersion = '1.5.3-preview01'; ExpectedVersion = '1.5.3-preview02'}
        @{CurrentVersion = '1.5.3-preview09'; ExpectedVersion = '1.5.3-preview10'}
        @{CurrentVersion = '1.5.3-preview1'; ExpectedVersion = '1.5.3-preview2'}
        @{CurrentVersion = '1.5.3-rc1'; ExpectedVersion = '1.5.3-rc2'}
        @{CurrentVersion = '1.5.3-SNAPSHOT'; ExpectedVersion = '1.5.3-SNAPSHOT01'}
        @{CurrentVersion = '1.5.3-SNAPSHOT1'; ExpectedVersion = '1.5.3-SNAPSHOT2'}
    ) {
        InModuleScope $script:moduleName -Parameters @{TestCase = $_} {
            param($TestCase)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectJSON = '/tmp/project.json'
                    Version = $TestCase.CurrentVersion
                }
            }

            (Get-NovaVersionUpdatePlan -Label Minor -PreviewRelease).NewVersion.ToString() | Should -Be $TestCase.ExpectedVersion
        }
    }

    It 'Set-NovaModuleVersion writes a new semantic version to project.json without flattening nested package repositories' {
        InModuleScope $script:moduleName {
            $projectJsonPath = Join-Path $TestDrive 'project.json'
            Set-Content -LiteralPath $projectJsonPath -Encoding utf8 -Value @'
{
  "ProjectName": "AzureDevOpsAgentInstaller",
  "Version": "1.2.3",
  "Package": {
    "RepositoryUrl": "https://packages.example/raw/",
    "Auth": {
      "HeaderName": "Authorization",
      "Scheme": "Basic",
      "Token": "NEXUS_TOKEN"
    },
    "Repositories": [
      {
        "Name": "staging",
        "Url": "https://packages.example/raw/staging/",
        "Auth": {
          "TokenEnvironmentVariable": "NEXUS_STAGING_TOKEN"
        }
      }
    ]
  }
}
'@
            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectJSON = $projectJsonPath}}
            $warningMessages = $null

            $result = Set-NovaModuleVersion -Label Minor -PreviewRelease -Confirm:$false -WarningVariable warningMessages

            $updatedProject = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json

            $result.PreviousVersion | Should -Be '1.2.3'
            $result.NewVersion | Should -Be '1.3.0-preview'
            $result.Applied | Should -BeTrue
            $updatedProject.Version | Should -Be '1.3.0-preview'
            $updatedProject.Package.Auth.HeaderName | Should -Be 'Authorization'
            $updatedProject.Package.Repositories.Count | Should -Be 1
            ($updatedProject.Package.Repositories[0] -is [string]) | Should -BeFalse
            $updatedProject.Package.Repositories[0].Name | Should -Be 'staging'
            $updatedProject.Package.Repositories[0].Auth.TokenEnvironmentVariable | Should -Be 'NEXUS_STAGING_TOKEN'
            $warningMessages | Should -BeNullOrEmpty
        }
    }

    It 'Set-NovaModuleVersion delegates project.json persistence to Write-ProjectJsonData' {
        InModuleScope $script:moduleName {
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = '/tmp/project.json'
                    NewVersion = [semver]'1.3.0-preview'
                }
            }
            Mock Read-ProjectJsonData {
                [ordered]@{
                    Version = '1.2.3'
                    Package = [ordered]@{
                        Repositories = @(
                            [ordered]@{
                                Name = 'staging'
                            }
                        )
                    }
                }
            }
            Mock Write-ProjectJsonData {}

            $result = Set-NovaModuleVersion -Label Minor -PreviewRelease -Confirm:$false

            $result.ProjectFile | Should -Be '/tmp/project.json'
            $result.PreviousVersion | Should -Be '1.2.3'
            $result.NewVersion | Should -Be '1.3.0-preview'
            $result.Applied | Should -BeTrue
            Assert-MockCalled Read-ProjectJsonData -Times 1 -ParameterFilter {$ProjectJsonPath -eq '/tmp/project.json'}
            Assert-MockCalled Write-ProjectJsonData -Times 1 -ParameterFilter {
                $ProjectJsonPath -eq '/tmp/project.json' -and
                        $Data.Version -eq '1.3.0-preview' -and
                        $Data.Package.Repositories[0].Name -eq 'staging'
            }
        }
    }

    It 'Set-NovaModuleVersion returns a non-applied write result when WhatIf declines project.json persistence' {
        InModuleScope $script:moduleName {
            Mock Get-NovaVersionUpdatePlan {
                [pscustomobject]@{
                    ProjectFile = '/tmp/project.json'
                    NewVersion = [semver]'1.3.0-preview'
                }
            }
            Mock Read-ProjectJsonData {
                [ordered]@{
                    Version = '1.2.3'
                }
            }
            Mock Write-ProjectJsonData {throw 'should not persist during WhatIf'}

            $result = Set-NovaModuleVersion -Label Minor -PreviewRelease -WhatIf

            $result.ProjectFile | Should -Be '/tmp/project.json'
            $result.PreviousVersion | Should -Be '1.2.3'
            $result.NewVersion | Should -Be '1.3.0-preview'
            $result.Applied | Should -BeFalse
            Assert-MockCalled Read-ProjectJsonData -Times 1 -ParameterFilter {$ProjectJsonPath -eq '/tmp/project.json'}
            Assert-MockCalled Write-ProjectJsonData -Times 0
        }
    }

    It 'Publish-NovaBuiltModuleToRepository uses the PSGallery fallback api key without forcing verbose output' {
        InModuleScope $script:moduleName {
            $originalApiKey = $env:PSGALLERY_API
            try {
                $env:PSGALLERY_API = 'gallery-secret'
                $script:publishPsResourceBoundParameters = $null
                $script:publishPsResourceVerbosePreference = $null
                Mock Publish-PSResource {
                    $script:publishPsResourceBoundParameters = @{}
                    foreach ($key in $PSBoundParameters.Keys) {
                        $script:publishPsResourceBoundParameters[$key] = $PSBoundParameters[$key]
                    }
                    $script:publishPsResourceVerbosePreference = $VerbosePreference
                }

                Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist'}) -Repository PSGallery

                Assert-MockCalled Publish-PSResource -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Repository -eq 'PSGallery' -and $ApiKey -eq 'gallery-secret'}
                $script:publishPsResourceVerbosePreference | Should -Not -Be 'Continue'
            }
            finally {
                $env:PSGALLERY_API = $originalApiKey
            }
        }
    }

    It 'Publish-NovaBuiltModuleToRepository forwards verbose output only when explicitly requested' {
        InModuleScope $script:moduleName {
            $script:publishPsResourceVerbosePreference = $null
            Mock Publish-PSResource {
                $script:publishPsResourceVerbosePreference = $VerbosePreference
            }

            Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist'}) -Repository PSGallery -ApiKey 'gallery-secret' -Verbose

            Assert-MockCalled Publish-PSResource -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Repository -eq 'PSGallery' -and $ApiKey -eq 'gallery-secret'}
            $script:publishPsResourceVerbosePreference | Should -Be 'Continue'
        }
    }

    It 'Publish-NovaModule forwards repository publishing through the public command' {
        InModuleScope $script:moduleName {
            $publishAction = {
                param($ProjectInfo, $Repository, $ApiKey)

                Publish-NovaBuiltModuleToRepository @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Get-Command {[pscustomobject]@{ScriptBlock = $publishAction}} -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToRepository' -and $CommandType -eq 'Function'}

            Publish-NovaModule -Repository PSGallery -ApiKey repo-key

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'repo-key'}
        }
    }

    It 'Publish-NovaBuiltModule routes repository and local publish paths correctly' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{OutputModuleDir = '/tmp/dist'; ProjectName = 'NovaModuleTools'}
            Mock Test-Path {$true} -ParameterFilter {$LiteralPath -eq '/tmp/dist'}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Publish-NovaBuiltModuleToDirectory {}
            Mock Resolve-NovaLocalPublishPath {'/tmp/modules'}

            Publish-NovaBuiltModule -ProjectInfo $projectInfo -Repository PSGallery -ApiKey secret
            Publish-NovaBuiltModule -ProjectInfo $projectInfo

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'secret'}
            Assert-MockCalled Publish-NovaBuiltModuleToDirectory -Times 1 -ParameterFilter {$ModuleDirectoryPath -eq '/tmp/modules'}
        }
    }

    It 'Publish-NovaBuiltModule throws when dist is missing and Resolve-NovaLocalPublishPath returns explicit or local paths' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false}

            $thrown = $null
            try {
                Publish-NovaBuiltModule -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/missing'; ProjectName = 'Nova'})
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Dist folder is empty, build the module before running publish command'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Environment.ReleaseBuildOutputNotFound'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ObjectNotFound)
            $thrown.TargetObject | Should -Be '/tmp/missing'

            Mock Get-LocalModulePath {'/tmp/local-modules'}
            Resolve-NovaLocalPublishPath -ModuleDirectoryPath '/tmp/custom' | Should -Be '/tmp/custom'
            Resolve-NovaLocalPublishPath | Should -Be '/tmp/local-modules'
        }
    }

    It 'Get-NovaPublishedLocalManifestPath returns nothing for non-local publish invocations and resolves the local manifest path when enabled' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            $localInvocation = [pscustomobject]@{
                IsLocal = $true
                Target = '/tmp/modules'
                Parameters = @{ProjectInfo = $projectInfo}
            }

            Get-NovaPublishedLocalManifestPath -PublishInvocation ([pscustomobject]@{IsLocal = $false; Target = '/tmp/ignored'; Parameters = @{ProjectInfo = $projectInfo}}) | Should -BeNullOrEmpty
            Get-NovaPublishedLocalManifestPath -PublishInvocation $localInvocation | Should -Be (Join-Path '/tmp/modules/NovaModuleTools' 'NovaModuleTools.psd1')
        }
    }

    It 'Get-NovaLocalPublishActivation returns nothing for non-local publishes and resolves import details for local publishes' {
        InModuleScope $script:moduleName {
            $importAction = {'imported'}

            Mock Get-NovaPublishedLocalManifestPath {'/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'}
            Mock Get-Command {[pscustomobject]@{ScriptBlock = $importAction}} -ParameterFilter {
                $Name -eq 'Import-NovaPublishedLocalModule' -and $CommandType -eq 'Function'
            }

            Get-NovaLocalPublishActivation -PublishInvocation ([pscustomobject]@{IsLocal = $false}) | Should -BeNullOrEmpty

            $result = Get-NovaLocalPublishActivation -PublishInvocation ([pscustomobject]@{IsLocal = $true; Target = '/tmp/modules'; Parameters = @{ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}}})

            $result.ManifestPath | Should -Be '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
            $result.ImportAction | Should -Be $importAction
            Assert-MockCalled Get-NovaPublishedLocalManifestPath -Times 1
            Assert-MockCalled Get-Command -Times 1 -ParameterFilter {
                $Name -eq 'Import-NovaPublishedLocalModule' -and $CommandType -eq 'Function'
            }
        }
    }

    It 'Get-NovaInstalledProjectManifestPath delegates through the local publish manifest helper with the resolved target path' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'; ProjectRoot = '/tmp/project'}

            Mock Resolve-NovaLocalPublishPath {'/tmp/modules'}
            Mock Get-NovaPublishedLocalManifestPath {
                $PublishInvocation.IsLocal | Should -BeTrue
                $PublishInvocation.Target | Should -Be '/tmp/modules'
                $PublishInvocation.Parameters.ProjectInfo | Should -Be $projectInfo
                return '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
            }

            $result = Get-NovaInstalledProjectManifestPath -ProjectInfo $projectInfo -ModuleDirectoryPath '/tmp/custom-modules'

            $result | Should -Be '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'
            Assert-MockCalled Resolve-NovaLocalPublishPath -Times 1 -ParameterFilter {$ModuleDirectoryPath -eq '/tmp/custom-modules'}
            Assert-MockCalled Get-NovaPublishedLocalManifestPath -Times 1
        }
    }

    It 'Get-NovaInstalledProjectManifestPath resolves the default project info when ProjectInfo is omitted' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{ProjectName = 'AzureDevOpsAgentInstaller'; ProjectRoot = '/tmp/project'}
            }
            Mock Resolve-NovaLocalPublishPath {'/tmp/default-modules'}
            Mock Get-NovaPublishedLocalManifestPath {
                $PublishInvocation.IsLocal | Should -BeTrue
                $PublishInvocation.Target | Should -Be '/tmp/default-modules'
                $PublishInvocation.Parameters.ProjectInfo.ProjectName | Should -Be 'AzureDevOpsAgentInstaller'
                return '/tmp/default-modules/AzureDevOpsAgentInstaller/AzureDevOpsAgentInstaller.psd1'
            }

            $result = Get-NovaInstalledProjectManifestPath

            $result | Should -Be '/tmp/default-modules/AzureDevOpsAgentInstaller/AzureDevOpsAgentInstaller.psd1'
            Assert-MockCalled Get-NovaProjectInfo -Times 1
            Assert-MockCalled Resolve-NovaLocalPublishPath -Times 1
            Assert-MockCalled Get-NovaPublishedLocalManifestPath -Times 1
        }
    }

    It 'Get-NovaResolvedPublishParameterMap copies publish parameters and lets workflow values override matching keys' {
        InModuleScope $script:moduleName {
            $publishInvocation = [pscustomobject]@{
                Parameters = [ordered]@{
                    ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
                    Repository = 'PSGallery'
                    ApiKey = 'initial-key'
                }
            }

            $result = Get-NovaResolvedPublishParameterMap -PublishInvocation $publishInvocation -WorkflowParams @{ApiKey = 'workflow-key'; Confirm = $false}

            $result.ProjectInfo.ProjectName | Should -Be 'NovaModuleTools'
            $result.Repository | Should -Be 'PSGallery'
            $result.ApiKey | Should -Be 'workflow-key'
            $result.Confirm | Should -BeFalse
        }
    }

    It 'Import-NovaPublishedLocalModule fails clearly when the local manifest is missing' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false} -ParameterFilter {$LiteralPath -eq '/tmp/missing.psd1' -and $PathType -eq 'Leaf'}
            Mock Stop-NovaOperation {throw [System.InvalidOperationException]::new($Message)}

            {Import-NovaPublishedLocalModule -ProjectName 'NovaModuleTools' -ManifestPath '/tmp/missing.psd1'} | Should -Throw 'Expected locally published module manifest at: /tmp/missing.psd1'
            Assert-MockCalled Stop-NovaOperation -Times 1 -ParameterFilter {
                $Message -eq 'Expected locally published module manifest at: /tmp/missing.psd1' -and
                        $ErrorId -eq 'Nova.Environment.LocalPublishedModuleManifestNotFound' -and
                        $Category -eq 'ObjectNotFound' -and
                        $TargetObject -eq '/tmp/missing.psd1'
            }
        }
    }

    It 'Import-NovaPublishedLocalModule imports the requested local module manifest as a global module' {
        InModuleScope $script:moduleName {
            $importedModule = [pscustomobject]@{Path = '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'; Name = 'NovaModuleTools'}

            Mock Test-Path {$true}
            Mock Get-Module {@()}
            Mock Remove-Module {}
            Mock Import-Module {$importedModule}

            $result = Import-NovaPublishedLocalModule -ProjectName 'NovaModuleTools' -ManifestPath $importedModule.Path

            $result | Should -Be $importedModule
            Assert-MockCalled Import-Module -Times 1
        }
    }

    It 'Import-NovaPublishedLocalModule removes matching and stale loaded module instances around the import' {
        InModuleScope $script:moduleName {
            $importedModule = [pscustomobject]@{Path = '/tmp/modules/NovaModuleTools/NovaModuleTools.psd1'; Name = 'NovaModuleTools'}

            Mock Test-Path {$true} -ParameterFilter {$LiteralPath -eq $importedModule.Path -and $PathType -eq 'Leaf'}
            Mock Get-Module {
                @(
                    [pscustomobject]@{Path = $importedModule.Path}
                    [pscustomobject]@{Path = '/tmp/modules/NovaModuleTools/legacy.psd1'}
                )
            } -ParameterFilter {$Name -eq 'NovaModuleTools' -and $All}
            Mock Remove-Module {}
            Mock Import-Module {$importedModule} -ParameterFilter {
                $Name -eq $importedModule.Path -and $Force -and $Global -and $PassThru -and $ErrorAction -eq 'Stop'
            }

            $null = Import-NovaPublishedLocalModule -ProjectName 'NovaModuleTools' -ManifestPath $importedModule.Path

            Assert-MockCalled Remove-Module -Times 2
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns empty when the project is not a git repository' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'no-git-project'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 0
        }
    }

    It 'Get-NovaVersionLabelForBump falls back to Patch when the project is not a git repository' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'no-git-project-for-label'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            Get-NovaVersionLabelForBump -ProjectRoot $projectRoot | Should -Be 'Patch'
        }
    }

    It 'Get-GitCommitMessageForVersionBump uses the shared git adapter to resolve tagged commit history' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'mocked-git-history'
            New-Item -ItemType Directory -Path (Join-Path $projectRoot '.git') -Force | Out-Null

            Mock Invoke-NovaGitCommand {
                if ($Arguments[0] -eq 'describe') {
                    return [pscustomobject]@{ExitCode = 0; Output = @('v1.0.0')}
                }

                return [pscustomobject]@{
                    ExitCode = 0
                    Output = @(
                        'docs: update readme'
                        ''
                        '--END-COMMIT--'
                        'fix: patch bug'
                        'Detailed patch note'
                        '--END-COMMIT--'
                    )
                }
            }

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages | Should -Be @(
                'docs: update readme'
                "fix: patch bug$( [Environment]::NewLine )Detailed patch note"
            )
            Assert-MockCalled Invoke-NovaGitCommand -Times 1 -ParameterFilter {$ProjectRoot -eq $projectRoot -and $Arguments[0] -eq 'describe'}
            Assert-MockCalled Invoke-NovaGitCommand -Times 1 -ParameterFilter {$ProjectRoot -eq $projectRoot -and $Arguments[0] -eq 'log' -and $Arguments[1] -eq 'v1.0.0..HEAD'}
        }
    }

    It 'Get-NovaVersionLabelForBump uses the shared git adapter to detect a tagged head with no new commits' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'mocked-git-state'
            New-Item -ItemType Directory -Path (Join-Path $projectRoot '.git') -Force | Out-Null

            Mock Invoke-NovaGitCommand {
                switch ($Arguments[0]) {
                    'rev-parse' {
                        return [pscustomobject]@{ExitCode = 0; Output = @('.git')}
                    }
                    'describe' {
                        return [pscustomobject]@{ExitCode = 0; Output = @('v1.0.0')}
                    }
                    'rev-list' {
                        return [pscustomobject]@{ExitCode = 0; Output = @('0')}
                    }
                    default {
                        throw "Unexpected git args: $( $Arguments -join ' ' )"
                    }
                }
            }

            $thrown = $null
            try {
                Get-NovaVersionLabelForBump -ProjectRoot $projectRoot
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -Be 'Cannot bump version because there are no commits since the latest tag.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.NoCommitsSinceLatestTag'
            Assert-MockCalled Invoke-NovaGitCommand -Times 1 -ParameterFilter {$Arguments[0] -eq 'rev-list' -and $Arguments[2] -eq 'v1.0.0..HEAD'}
        }
    }

    It 'Get-NovaVersionLabelForBump returns Patch when the repository has commits but no tags yet' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'mocked-git-without-tags'
            New-Item -ItemType Directory -Path (Join-Path $projectRoot '.git') -Force | Out-Null

            Mock Invoke-NovaGitCommand {
                switch ($Arguments[0]) {
                    'rev-parse' {
                        return [pscustomobject]@{ExitCode = 0; Output = @('.git')}
                    }
                    'describe' {
                        return [pscustomobject]@{ExitCode = 1; Output = @()}
                    }
                    default {
                        throw "Unexpected git args: $( $Arguments -join ' ' )"
                    }
                }
            }

            Get-NovaVersionLabelForBump -ProjectRoot $projectRoot | Should -Be 'Patch'
            Assert-MockCalled Invoke-NovaGitCommand -Times 1 -ParameterFilter {$Arguments[0] -eq 'describe' -and $Arguments[1] -eq '--tags'}
            Assert-MockCalled Invoke-NovaGitCommand -Times 0 -ParameterFilter {$Arguments[0] -eq 'rev-list'}
        }
    }

    It 'Get-NovaVersionLabelForBump throws a clear error when the repository has no commits yet' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'empty-git-project'
            Initialize-TestGitRepository -Path $projectRoot

            $thrown = $null
            try {
                Get-NovaVersionLabelForBump -ProjectRoot $projectRoot
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -Be 'Cannot bump version because the repository has no commits yet. Create an initial commit first.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.GitRepositoryHasNoCommits'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidOperation)
            $thrown.TargetObject | Should -Be $projectRoot
        }
    }

    It 'Get-NovaVersionLabelForBump throws when there are no commits since the latest tag' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'tagged-head-git-project'
            Initialize-TestGitRepository -Path $projectRoot
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'feat: initial release' -File @{Name = 'first.txt'; Content = 'first'}
            New-TestGitTag -RepositoryPath $projectRoot -TagName 'v1.0.0'

            $thrown = $null
            try {
                Get-NovaVersionLabelForBump -ProjectRoot $projectRoot
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -Be 'Cannot bump version because there are no commits since the latest tag.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.NoCommitsSinceLatestTag'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidOperation)
            $thrown.TargetObject | Should -Be $projectRoot
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns commits since the latest tag when tags exist' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'tagged-git-project'
            Initialize-TestGitRepository -Path $projectRoot
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'feat: initial release' -File @{Name = 'first.txt'; Content = 'first'}
            New-TestGitTag -RepositoryPath $projectRoot -TagName 'v1.0.0'
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'fix: patch bug' -Body 'Detailed patch note' -File @{Name = 'second.txt'; Content = 'second'}
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'docs: update readme' -File @{Name = 'third.txt'; Content = 'third'}

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 2
            $messages[0] | Should -Be 'docs: update readme'
            $messages[1] | Should -Be "fix: patch bug$( [Environment]::NewLine )Detailed patch note"
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns all commits when no tags exist' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'untagged-git-project'
            Initialize-TestGitRepository -Path $projectRoot
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'feat: add capability' -Body 'Implements the new path' -File @{Name = 'first.txt'; Content = 'first'}
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'chore: tidy metadata' -File @{Name = 'second.txt'; Content = 'second'}

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 2
            $messages[0] | Should -Be 'chore: tidy metadata'
            $messages[1] | Should -Be "feat: add capability$( [Environment]::NewLine )Implements the new path"
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns empty when the git directory exists but git log fails' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'broken-git-project'
            New-Item -ItemType Directory -Path (Join-Path $projectRoot '.git') -Force | Out-Null

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 0
        }
    }

    It 'Get-ResourceFilePath falls back cleanly and throws when no candidate exists' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {throw 'not a project'}
            Mock Test-Path {$false}

            $thrown = $null
            try {
                Get-ResourceFilePath -FileName 'missing.json'
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -BeLike 'Resource file not found: missing.json*'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Environment.ResourceFileNotFound'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ObjectNotFound)
            $thrown.TargetObject | Should -Be 'missing.json'
        }
    }
}
