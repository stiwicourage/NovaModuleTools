BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage completion for remaining low-coverage helpers' {
    It 'Test-ProjectSchema validates the Pester schema' {
        InModuleScope $script:moduleName {
            Mock Get-ResourceFilePath {
                if ($FileName -eq 'Schema-Build.json') {
                    return '/tmp/build-schema.json'
                }

                return '/tmp/pester-schema.json'
            }
            Mock Get-Content {
                if ($Path -eq '/tmp/pester-schema.json') {
                    return '{"title":"pester"}'
                }

                return '{"title":"build"}'
            }
            Mock Test-Json {$true}

            Test-ProjectSchema -Schema Pester | Should -BeTrue

            Assert-MockCalled Test-Json -Times 1 -ParameterFilter {
                $Path -eq 'project.json' -and $Schema -eq '{"title":"pester"}'
            }
        }
    }

    It 'Get-LocalModulePathPattern and Get-LocalModulePathErrorMessage return the current platform defaults' {
        InModuleScope $script:moduleName {
            $pattern = Get-LocalModulePathPattern
            $message = Get-LocalModulePathErrorMessage -MatchPattern $pattern

            if ($IsWindows) {
                $pattern | Should -Be '\\Documents\\PowerShell\\Modules'
                $message | Should -Be "No windows module path matching $pattern found"
            }
            else {
                $pattern | Should -Be '/\.local/share/powershell/Modules$'
                $message | Should -Be "No macOS/Linux module path matching $pattern found in PSModulePath."
            }
        }
    }

    It 'Get-FunctionSourceIndex adds entries for indexable files' {
        InModuleScope $script:moduleName {
            $sourceFile = Get-Item -LiteralPath (Join-Path $TestDrive 'Example.ps1') -ErrorAction SilentlyContinue
            if (-not $sourceFile) {
                Set-Content -LiteralPath (Join-Path $TestDrive 'Example.ps1') -Value 'function Get-Example { }'
                $sourceFile = Get-Item -LiteralPath (Join-Path $TestDrive 'Example.ps1')
            }

            Mock Get-IndexableSourceFile {@($File)}
            Mock Add-FunctionSourceIndexEntryFromFile {
                $Index['Get-Example'] = @([pscustomobject]@{Path = $File.FullName; Line = 1})
            }

            $index = Get-FunctionSourceIndex -File $sourceFile

            $index['Get-Example'][0].Line | Should -Be 1
            $index['Get-Example'][0].Path | Should -Be $sourceFile.FullName
        }
    }

    It 'Assert-BuiltModuleHasNoDuplicateFunctionName throws when the built module file is missing' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false}

            {
                Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo ([pscustomobject]@{ModuleFilePSM1 = '/tmp/missing.psm1'})
            } | Should -Throw 'Built module file not found*'
        }
    }

    It 'Assert-BuiltModuleHasNoDuplicateFunctionName throws when the built module has parse errors' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$true}
            Mock Get-PowerShellAstFromFile {
                [pscustomobject]@{
                    Errors = @([pscustomobject]@{Message = 'unexpected token'})
                    Ast = $null
                }
            }

            {
                Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo ([pscustomobject]@{ModuleFilePSM1 = '/tmp/bad.psm1'})
            } | Should -Throw 'Built module contains parse errors*unexpected token'
        }
    }

    It 'Publish-NovaBuiltModuleToDirectory creates the destination when it is missing' {
        InModuleScope $script:moduleName {
            Mock Test-Path {
                if ($LiteralPath -eq '/tmp/modules' -and $PathType -eq 'Container') {
                    return $false
                }

                return $false
            }
            Mock New-Item {[pscustomobject]@{FullName = $Path}}
            Mock Remove-Item {}
            Mock Copy-Item {}

            Publish-NovaBuiltModuleToDirectory -ProjectInfo ([pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}) -ModuleDirectoryPath '/tmp/modules'

            Assert-MockCalled New-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/modules' -and $ItemType -eq 'Directory' -and $Force}
            Assert-MockCalled Remove-Item -Times 0
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Destination -eq '/tmp/modules' -and $Recurse}
        }
    }

    It 'Publish-NovaBuiltModuleToDirectory removes an existing module copy before copying' {
        InModuleScope $script:moduleName {
            Mock Test-Path {
                if ($LiteralPath -eq '/tmp/modules' -and $PathType -eq 'Container') {
                    return $true
                }

                return $LiteralPath -eq '/tmp/modules/NovaModuleTools'
            }
            Mock New-Item {}
            Mock Remove-Item {}
            Mock Copy-Item {}

            Publish-NovaBuiltModuleToDirectory -ProjectInfo ([pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}) -ModuleDirectoryPath '/tmp/modules'

            Assert-MockCalled New-Item -Times 0
            Assert-MockCalled Remove-Item -Times 1 -ParameterFilter {$LiteralPath -eq '/tmp/modules/NovaModuleTools' -and $Recurse -and $Force}
            Assert-MockCalled Copy-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Destination -eq '/tmp/modules' -and $Recurse}
        }
    }

    It 'Invoke-NovaRelease uses repository publishing when a repository is supplied' {
        InModuleScope $script:moduleName {
            $publishAction = {
                param($ProjectInfo, $Repository, $ApiKey)

                Publish-NovaBuiltModuleToRepository @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Update-NovaModuleVersion {[pscustomobject]@{NewVersion = '2.0.0'}}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Get-Command {[pscustomobject]@{ScriptBlock = $publishAction}} -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToRepository' -and $CommandType -eq 'Function'}

            $result = Invoke-NovaRelease -PublishOption @{Repository = 'PSGallery'; ApiKey = 'repo-key'} -Path (Get-Location).Path

            $result.NewVersion | Should -Be '2.0.0'
            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'repo-key'}
        }
    }

    It 'Update-NovaModuleVersion updates the version when the change is approved' {
        InModuleScope $script:moduleName {
            $script:getNovaProjectInfoCallCount = 0
            $projectRoot = Join-Path $TestDrive 'project-root'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            Mock Get-NovaProjectInfo {
                $script:getNovaProjectInfoCallCount += 1
                if ($script:getNovaProjectInfoCallCount -eq 1) {
                    return [pscustomobject]@{Version = '1.2.3'; ProjectJSON = (Join-Path $projectRoot 'project.json')}
                }

                return [pscustomobject]@{Version = '1.2.4'; ProjectJSON = (Join-Path $projectRoot 'project.json')}
            }
            Mock Get-GitCommitMessageForVersionBump {@('fix: patch bug')}
            Mock Get-VersionLabelFromCommitSet {'Patch'}
            Mock Set-NovaModuleVersion {}

            $result = Update-NovaModuleVersion -Path $projectRoot -Confirm:$false

            $result.PreviousVersion | Should -Be '1.2.3'
            $result.NewVersion | Should -Be '1.2.4'
            $result.Label | Should -Be 'Patch'
            $result.CommitCount | Should -Be 1
            Assert-MockCalled Set-NovaModuleVersion -Times 1 -ParameterFilter {$Label -eq 'Patch'}
        }
    }

    It 'New-InitiateGitRepo warns when git is unavailable' {
        InModuleScope $script:moduleName {
            Mock Get-Command {$null} -ParameterFilter {$Name -eq 'git'}
            Mock Write-Warning {}

            New-InitiateGitRepo -DirectoryPath $TestDrive -Confirm:$false

            Assert-MockCalled Write-Warning -Times 1 -ParameterFilter {$Message -like 'Git is not installed*'}
        }
    }

    It 'New-InitiateGitRepo initializes a git repository when git is available' {
        InModuleScope $script:moduleName {
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'git is not available in this environment'
                return
            }

            $repoPath = Join-Path $TestDrive 'git-init'
            New-Item -ItemType Directory -Path $repoPath -Force | Out-Null

            New-InitiateGitRepo -DirectoryPath $repoPath -Confirm:$false

            Test-Path -LiteralPath (Join-Path $repoPath '.git') | Should -BeTrue
        }
    }
}






