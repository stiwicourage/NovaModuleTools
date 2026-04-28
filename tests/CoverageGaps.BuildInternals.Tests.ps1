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

Describe 'Coverage gaps for build and duplicate-analysis internals' {
    It 'Get-NovaBuildWorkflowContext resolves project info once and returns the public build operation metadata' {
        InModuleScope $script:moduleName {
            Mock Get-NovaBuildProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }

            $result = Get-NovaBuildWorkflowContext

            $result.ProjectInfo.ProjectName | Should -Be 'NovaModuleTools'
            $result.Target | Should -Be '/tmp/dist/NovaModuleTools'
            $result.Operation | Should -Be 'Build Nova module output'
            $result.ContinuousIntegrationRequested | Should -BeFalse
            Assert-MockCalled Get-NovaBuildProjectInfo -Times 1 -ParameterFilter {$null -eq $ProjectInfo}
        }
    }

    It 'Get-NovaBuildWorkflowContext carries ContinuousIntegrationRequested when requested' {
        InModuleScope $script:moduleName {
            Mock Get-NovaBuildProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }

            $result = Get-NovaBuildWorkflowContext -ContinuousIntegrationRequested

            $result.ContinuousIntegrationRequested | Should -BeTrue
        }
    }

    It 'Resolve-NovaCiProjectInfo uses the current location when ProjectRoot is omitted' {
        $expectedPath = (Get-Location).Path

        InModuleScope $script:moduleName -Parameters @{ExpectedPath = $expectedPath} {
            param($ExpectedPath)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            } -ParameterFilter {$Path -eq $ExpectedPath}

            $result = Resolve-NovaCiProjectInfo

            $result.ProjectName | Should -Be 'NovaModuleTools'
            Assert-MockCalled Get-NovaProjectInfo -Times 1 -ParameterFilter {$Path -eq $ExpectedPath}
        }
    }

    It 'Resolve-NovaCiProjectInfo returns the provided ProjectInfo without resolving it again' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                OutputModuleDir = '/tmp/dist/NovaModuleTools'
            }
            Mock Get-NovaProjectInfo {throw 'should not resolve project info'}

            $result = Resolve-NovaCiProjectInfo -ProjectInfo $projectInfo

            $result | Should -Be $projectInfo
            Assert-MockCalled Get-NovaProjectInfo -Times 0
        }
    }

    It 'Import-NovaBuiltModuleForCi resolves the built manifest path from the current location and imports it globally' {
        $expectedPath = (Get-Location).Path

        InModuleScope $script:moduleName -Parameters @{ExpectedPath = $expectedPath} {
            param($ExpectedPath)

            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            } -ParameterFilter {$Path -eq $ExpectedPath}
            Mock Test-Path {$true} -ParameterFilter {$LiteralPath -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'}
            Mock Get-Module {@()}
            Mock Import-Module {
                [pscustomobject]@{Path = $Name}
            } -ParameterFilter {$Name -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1' -and $Force -and $Global -and $PassThru}

            $result = Import-NovaBuiltModuleForCi

            $result.Path | Should -Be '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'
            Assert-MockCalled Get-NovaProjectInfo -Times 1 -ParameterFilter {$Path -eq $ExpectedPath}
            Assert-MockCalled Import-Module -Times 1 -ParameterFilter {$Name -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1' -and $Force -and $Global -and $PassThru}
        }
    }

    It 'Import-NovaBuiltModuleForCi throws a stable error when the built manifest is missing' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
                [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                }
            }
            Mock Test-Path {$false} -ParameterFilter {$LiteralPath -eq '/tmp/dist/NovaModuleTools/NovaModuleTools.psd1'}
            Mock Get-Module {throw 'should not enumerate modules'}
            Mock Import-Module {throw 'should not import when manifest is missing'}

            {Import-NovaBuiltModuleForCi -ProjectRoot '/tmp/project'} | Should -Throw 'Built module manifest not found: /tmp/dist/NovaModuleTools/NovaModuleTools.psd1'

            Assert-MockCalled Get-Module -Times 0
            Assert-MockCalled Import-Module -Times 0
        }
    }

    It 'Invoke-NovaBuildDuplicateValidation skips duplicate analysis when the project disables that quality gate' {
        InModuleScope $script:moduleName {
            Mock Assert-BuiltModuleHasNoDuplicateFunctionName {throw 'should not validate duplicates'}

            $result = Invoke-NovaBuildDuplicateValidation -ProjectInfo ([pscustomobject]@{FailOnDuplicateFunctionNames = $false})

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Assert-BuiltModuleHasNoDuplicateFunctionName -Times 0
        }
    }

    It 'Invoke-NovaBuildUpdateNotificationSafely swallows update lookup failures' {
        InModuleScope $script:moduleName {
            Mock Invoke-NovaBuildUpdateNotification {throw 'network issue'}

            {Invoke-NovaBuildUpdateNotificationSafely} | Should -Not -Throw
            Assert-MockCalled Invoke-NovaBuildUpdateNotification -Times 1
        }
    }

    It 'Build-Help skips when no markdown files exist' {
        InModuleScope $script:moduleName {
            Mock Get-NovaBuildProjectInfo {[pscustomobject]@{DocsDir = '/tmp/docs'}}
            Mock Get-ChildItem {@()}
            Mock Get-Module {}

            Build-Help

            Assert-MockCalled Get-Module -Times 0
        }
    }

    It 'Build-Help throws when PlatyPS is unavailable and docs exist' {
        InModuleScope $script:moduleName {
            Mock Get-NovaBuildProjectInfo {[pscustomobject]@{DocsDir = '/tmp/docs'}}
            Mock Get-ChildItem {@([pscustomobject]@{FullName = '/tmp/docs/Invoke-NovaBuild.md'})}
            Mock Get-Module {$null}

            $thrown = $null
            try {
                Build-Help
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -BeLike 'The module Microsoft.PowerShell.PlatyPS must be installed*'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.BuildHelpDependencyMissing'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ResourceUnavailable)
            $thrown.TargetObject | Should -Be 'Microsoft.PowerShell.PlatyPS'
        }
    }

    It 'Build-Help imports markdown help and renames the generated locale folder' {
        InModuleScope $script:moduleName {
            $docPath = Join-Path $TestDrive 'Invoke-NovaBuild.md'
            Set-Content -LiteralPath $docPath -Value "---`nLocale: da-DK`n---"

            Mock Get-NovaBuildProjectInfo {
                [pscustomobject]@{
                    DocsDir = '/tmp/docs'
                    OutputModuleDir = '/tmp/dist'
                    ProjectName = 'NovaModuleTools'
                }
            }
            Mock Get-ChildItem {@(Get-Item -LiteralPath $docPath)}
            Mock Get-Module {[pscustomobject]@{Name = 'Microsoft.PowerShell.PlatyPS'}}
            Mock Measure-PlatyPSMarkdown {[pscustomobject]@{FileType = 'CommandHelp'; FilePath = '/tmp/docs/Invoke-NovaBuild.md'}}
            Mock Get-NovaHelpLocale {'da-DK'}
            Mock Rename-Item {}

            $script:buildHelpExportOutputFolder = $null
            function Import-MarkdownCommandHelp {
                [CmdletBinding()]
                param(
                    [Parameter(ValueFromPipeline)]
                    [object]$InputObject,

                    [object]$Path
                )

                process {
                    [pscustomobject]@{Name = 'Invoke-NovaBuild'}
                }
            }

            function Export-MamlCommandHelp {
                [CmdletBinding()]
                param(
                    [Parameter(ValueFromPipeline)]
                    [object]$InputObject,

                    [string]$OutputFolder
                )

                process {
                    $script:buildHelpExportOutputFolder = $OutputFolder
                }
            }

            try {
                Build-Help
            }
            finally {
                Remove-Item function:Import-MarkdownCommandHelp -ErrorAction SilentlyContinue
                Remove-Item function:Export-MamlCommandHelp -ErrorAction SilentlyContinue
            }

            $script:buildHelpExportOutputFolder | Should -Be '/tmp/dist'
            Assert-MockCalled Rename-Item -Times 1 -ParameterFilter {$Path -eq '/tmp/dist/NovaModuleTools' -and $NewName -eq '/tmp/dist/da-DK'}
        }
    }

    It 'Build-Module exposes structured errors when there are no source files or the psm1 write fails' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                ClassesDir = '/tmp/classes'
                PublicDir = '/tmp/public'
                PrivateDir = '/tmp/private'
                ModuleFilePSM1 = '/tmp/NovaModuleTools.psm1'
            }
            $sourceFilePath = Join-Path $TestDrive 'Get-Thing.ps1'
            Set-Content -LiteralPath $sourceFilePath -Value 'function Get-Thing { }' -Encoding utf8
            $sourceFile = Get-Item -LiteralPath $sourceFilePath

            Mock Get-NovaBuildProjectInfo {$projectInfo}
            Mock Get-Command {[pscustomobject]@{Version = [version]'2.0.0'}} -ParameterFilter {$Name -eq 'Invoke-NovaBuild'}
            Mock Test-ProjectSchema {}
            Mock Add-ProjectPreambleToModuleBuilder {}
            Mock Get-ProjectScriptFile {@()}
            Mock Get-ChildItem {@()}

            $missingSourceError = $null
            try {
                Build-Module -ProjectInfo $projectInfo
            }
            catch {
                $missingSourceError = $_
            }

            $missingSourceError.Exception.Message | Should -Be 'No source files found to build. Add one or more scripts under src/public, src/private, or src/classes.'
            $missingSourceError.FullyQualifiedErrorId | Should -Be 'Nova.Environment.BuildSourceFilesNotFound'
            $missingSourceError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ObjectNotFound)
            $missingSourceError.TargetObject | Should -Be 'src'

            Mock Get-ProjectScriptFile {@($sourceFile)}
            Mock Add-ScriptFileContentToModuleBuilder {}
            Mock Set-Content {throw 'disk full'}

            $psm1WriteError = $null
            try {
                Build-Module -ProjectInfo $projectInfo
            }
            catch {
                $psm1WriteError = $_
            }

            $psm1WriteError.Exception.Message | Should -Be 'Failed to create psm1 file: disk full'
            $psm1WriteError.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.ModulePsm1CreationFailed'
            $psm1WriteError.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::OpenError)
            $psm1WriteError.TargetObject | Should -Be '/tmp/NovaModuleTools.psm1'
        }
    }

    It 'Build-Manifest includes expected resource paths and prerelease manifest metadata when resources go to <ResourceLocation>' -ForEach @(
        @{
            ResourceLocation = 'resources/'
            CopyResourcesToModuleRoot = $false
            ExpectedFormatPath = 'resources/Nova.Format.ps1xml'
            ExpectedTypePath = 'resources/Nova.Types.ps1xml'
        }
        @{
            ResourceLocation = 'module root'
            CopyResourcesToModuleRoot = $true
            ExpectedFormatPath = 'Nova.Format.ps1xml'
            ExpectedTypePath = 'Nova.Types.ps1xml'
        }
    ) {
        InModuleScope $script:moduleName -Parameters @{ManifestCase = $_} {
            param($ManifestCase)

            $projectInfo = [pscustomobject]@{
                PublicDir = '/tmp/public'
                ResourcesDir = '/tmp/resources'
                CopyResourcesToModuleRoot = $ManifestCase.CopyResourcesToModuleRoot
                Manifest = [ordered]@{Author = 'Tester'; CompanyName = 'Nova'}
                Version = '1.2.3-preview'
                Description = 'Example'
                ProjectName = 'NovaModuleTools'
                ManifestFilePSD1 = '/tmp/NovaModuleTools.psd1'
            }
            Mock Get-NovaBuildProjectInfo {$projectInfo}
            Mock Get-ChildItem {@([pscustomobject]@{FullName = '/tmp/public/Get-Thing.ps1'})} -ParameterFilter {$Path -eq '/tmp/public'}
            Mock Get-ChildItem {@([pscustomobject]@{Name = 'Nova.Format.ps1xml'})} -ParameterFilter {$Filter -eq '*Format.ps1xml'}
            Mock Get-ChildItem {@([pscustomobject]@{Name = 'Nova.Types.ps1xml'})} -ParameterFilter {$Filter -eq '*Types.ps1xml'}
            Mock Get-FunctionNameFromFile {'Get-Thing'}
            Mock Get-AliasInFunctionFromFile {'gt'}
            Mock Assert-ManifestSchema {}
            Mock New-ModuleManifest {}

            Build-Manifest -ProjectInfo $projectInfo

            Assert-MockCalled New-ModuleManifest -Times 1 -ParameterFilter {
                $Path -eq '/tmp/NovaModuleTools.psd1' -and
                        $FunctionsToExport -eq @('Get-Thing') -and
                        $AliasesToExport -eq @('gt') -and
                        $FormatsToProcess -eq @($ManifestCase.ExpectedFormatPath) -and
                        $TypesToProcess -eq @($ManifestCase.ExpectedTypePath) -and
                        $Prerelease -eq 'preview' -and
                        $Author -eq 'Tester' -and
                        $CompanyName -eq 'Nova'
            }
        }
    }

    It 'Build-Manifest reports manifest creation failures' {
        InModuleScope $script:moduleName {
            Mock Get-NovaBuildProjectInfo {
                [pscustomobject]@{
                    PublicDir = '/tmp/public'
                    ResourcesDir = '/tmp/resources'
                    CopyResourcesToModuleRoot = $false
                    Manifest = [ordered]@{Author = 'Tester'; CompanyName = 'Nova'}
                    Version = '1.2.3-preview'
                    Description = 'Example'
                    ProjectName = 'NovaModuleTools'
                    ManifestFilePSD1 = '/tmp/NovaModuleTools.psd1'
                }
            }
            Mock Get-ChildItem {@([pscustomobject]@{FullName = '/tmp/public/Get-Thing.ps1'})} -ParameterFilter {$Path -eq '/tmp/public'}
            Mock Get-ChildItem {@([pscustomobject]@{Name = 'Nova.Format.ps1xml'})} -ParameterFilter {$Filter -eq '*Format.ps1xml'}
            Mock Get-ChildItem {@([pscustomobject]@{Name = 'Nova.Types.ps1xml'})} -ParameterFilter {$Filter -eq '*Types.ps1xml'}
            Mock Get-FunctionNameFromFile {'Get-Thing'}
            Mock Get-AliasInFunctionFromFile {'gt'}
            Mock Assert-ManifestSchema {}
            Mock New-ModuleManifest {throw 'manifest failed'}

            $thrown = $null
            try {
                Build-Manifest -ProjectInfo ([pscustomobject]@{
                    PublicDir = '/tmp/public'
                    ResourcesDir = '/tmp/resources'
                    CopyResourcesToModuleRoot = $false
                    Manifest = [ordered]@{Author = 'Tester'; CompanyName = 'Nova'}
                    Version = '1.2.3-preview'
                    Description = 'Example'
                    ProjectName = 'NovaModuleTools'
                    ManifestFilePSD1 = '/tmp/NovaModuleTools.psd1'
                })
            }
            catch {
                $thrown = $_
            }

            $thrown.Exception.Message | Should -BeLike 'Failed to create Manifest*'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.ModuleManifestCreationFailed'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::OpenError)
            $thrown.TargetObject | Should -Be '/tmp/NovaModuleTools.psd1'
        }
    }

    It 'Format-DuplicateFunctionErrorMessage includes dist and source locations' {
        InModuleScope $script:moduleName {
            $duplicateGroup = @(
                [pscustomobject]@{
                    Name = 'Invoke-Dup'
                    Group = @(
                        [pscustomobject]@{Name = 'Invoke-Dup'; Extent = [pscustomobject]@{StartLineNumber = 12}},
                        [pscustomobject]@{Name = 'Invoke-Dup'; Extent = [pscustomobject]@{StartLineNumber = 34}}
                    )
                }
            )
            $sourceIndex = @{
                'Invoke-Dup' = @(
                    [pscustomobject]@{Path = 'src/public/Dup.ps1'; Line = 3},
                    [pscustomobject]@{Path = 'src/private/Dup.ps1'; Line = 9}
                )
            }

            $message = Format-DuplicateFunctionErrorMessage -Psm1Path '/tmp/Nova.psm1' -DuplicateGroup $duplicateGroup -SourceIndex $sourceIndex

            $message | Should -Match 'Duplicate top-level function names detected in built module: /tmp/Nova.psm1'
            $message | Should -Match 'dist line 12'
            $message | Should -Match 'src/public/Dup.ps1:3'
            $message | Should -Match 'src/private/Dup.ps1:9'
        }
    }

    It 'Format-ProjectJsonValue returns null for null input' {
        InModuleScope $script:moduleName {
            Format-ProjectJsonValue -Value $null | Should -Be 'null'
        }
    }

    It 'Format-ProjectJsonValue falls back to string conversion when ConvertTo-Json fails' {
        InModuleScope $script:moduleName {
            Mock ConvertTo-Json {throw 'json failed'}

            Format-ProjectJsonValue -Value 42 | Should -Be '42'
        }
    }

    It 'Get-ProjectJsonValueTypeName returns null for null input' {
        InModuleScope $script:moduleName {
            Get-ProjectJsonValueTypeName -Value $null | Should -Be 'null'
        }
    }

    It 'Get-ProjectJsonValueTypeName returns the CLR type name for non-null values' {
        InModuleScope $script:moduleName {
            Get-ProjectJsonValueTypeName -Value 42 | Should -Be 'System.Int32'
        }
    }

    It 'Get-TopLevelFunctionAst returns only top-level functions and Get-TopLevelFunctionAstFromFile ignores parse errors' {
        InModuleScope $script:moduleName {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(@'
function Outer {
    function Inner { "nested" }
    "outer"
}

function Second {
    "second"
}
'@, [ref]$tokens, [ref]$errors)

            $topLevel = @(Get-TopLevelFunctionAst -Ast $ast)

            $topLevel.Name | Should -Be @('Outer', 'Second')

            Mock Get-PowerShellAstFromFile {
                [pscustomobject]@{
                    Errors = @([pscustomobject]@{Message = 'parse error'})
                    Ast = $null
                }
            }

            @(Get-TopLevelFunctionAstFromFile -Path '/tmp/bad.ps1').Count | Should -Be 0
        }
    }

    It 'Get-DuplicateFunctionSourceLine handles missing and present source indexes' {
        InModuleScope $script:moduleName {
            $missingSourceIndexLines = @(Get-DuplicateFunctionSourceLine -Key 'Invoke-Dup' -SourceIndex $null)
            $missingSourceIndexLines.Count | Should -Be 0
            $emptyIndex = @{}
            $emptyIndexLines = @(Get-DuplicateFunctionSourceLine -Key 'Invoke-Dup' -SourceIndex $emptyIndex)
            $emptyIndexLines.Count | Should -Be 0

            $sourceIndex = @{
                'Invoke-Dup' = @(
                    [pscustomobject]@{Path = 'src/b.ps1'; Line = 8},
                    [pscustomobject]@{Path = 'src/a.ps1'; Line = 2}
                )
            }
            $lines = Get-DuplicateFunctionSourceLine -Key 'Invoke-Dup' -SourceIndex $sourceIndex

            $lines | Should -Be @(
                '  - source files:',
                '    - src/a.ps1:2',
                '    - src/b.ps1:8'
            )
        }
    }
}
