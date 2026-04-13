BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"
    $script:projectTemplatePath = Join-Path $script:repoRoot 'src/resources/ProjectTemplate.json'

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage gaps for scaffold, CLI, release, and helper internals' {
    It 'Get-NovaModuleQuestionSet returns the expected scaffold questions' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet

            $questions.Keys | Should -Be @(
                'ProjectName',
                'Description',
                'Version',
                'Author',
                'PowerShellHostVersion',
                'EnableGit',
                'EnablePester'
            )
            $questions.ProjectName.Default | Should -Be 'MANDATORY'
            $questions.EnableGit.Choice.Yes | Should -Be 'Enable Git'
            $questions.EnablePester.Choice.No | Should -Be 'Skip pester testing'
        }
    }

    It 'Get-NovaModuleScaffoldLayout returns the expected scaffold paths' {
        InModuleScope $script:moduleName {
            $layout = Get-NovaModuleScaffoldLayout -Path '/tmp/root' -ProjectName 'NovaSample'

            $layout.Project | Should -Be '/tmp/root/NovaSample'
            $layout.Src | Should -Be '/tmp/root/NovaSample/src'
            $layout.Private | Should -Be '/tmp/root/NovaSample/src/private'
            $layout.Public | Should -Be '/tmp/root/NovaSample/src/public'
            $layout.Resources | Should -Be '/tmp/root/NovaSample/src/resources'
            $layout.Classes | Should -Be '/tmp/root/NovaSample/src/classes'
            $layout.Tests | Should -Be '/tmp/root/NovaSample/tests'
            $layout.ProjectJsonFile | Should -Be '/tmp/root/NovaSample/project.json'
        }
    }

    It 'Read-NovaModuleAnswerSet reads answers for every scaffold question' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            Mock Read-AwesomeHost {
                switch ($Ask.Caption) {
                    'Module Name' {
                        'NovaSample'
                    }
                    'Module Description' {
                        'Sample module'
                    }
                    'Semantic Version' {
                        '1.2.3'
                    }
                    'Module Author' {
                        'Tester'
                    }
                    'Supported PowerShell Version' {
                        '7.4'
                    }
                    'Git Version Control' {
                        'No'
                    }
                    'Pester Testing' {
                        'Yes'
                    }
                    default {
                        throw "Unexpected prompt: $( $Ask.Caption )"
                    }
                }
            }

            $answers = Read-NovaModuleAnswerSet -Questions $questions

            $answers.ProjectName | Should -Be 'NovaSample'
            $answers.Description | Should -Be 'Sample module'
            $answers.Version | Should -Be '1.2.3'
            $answers.Author | Should -Be 'Tester'
            $answers.PowerShellHostVersion | Should -Be '7.4'
            $answers.EnableGit | Should -Be 'No'
            $answers.EnablePester | Should -Be 'Yes'
            Assert-MockCalled Read-AwesomeHost -Times $questions.Count
        }
    }

    It 'Read-NovaModuleAnswerSet rejects invalid project names' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            Mock Read-AwesomeHost {
                switch ($Ask.Caption) {
                    'Module Name' {
                        'bad name'
                    }
                    'Module Description' {
                        'Sample module'
                    }
                    'Semantic Version' {
                        '1.2.3'
                    }
                    'Module Author' {
                        'Tester'
                    }
                    'Supported PowerShell Version' {
                        '7.4'
                    }
                    'Git Version Control' {
                        'No'
                    }
                    'Pester Testing' {
                        'No'
                    }
                    default {
                        throw "Unexpected prompt: $( $Ask.Caption )"
                    }
                }
            }
            {Read-NovaModuleAnswerSet -Questions $questions} | Should -Throw 'Module name is invalid*'
        }
    }

    It 'Initialize-NovaModuleScaffold creates directories and optional integrations' {
        InModuleScope $script:moduleName {
            $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'Scaffolded'
            $answer = @{
                EnablePester = 'Yes'
                EnableGit = 'Yes'
            }
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            Initialize-NovaModuleScaffold -Answer $answer -Paths $paths

            foreach ($directory in @($paths.Project, $paths.Src, $paths.Private, $paths.Public, $paths.Resources, $paths.Classes, $paths.Tests)) {
                Test-Path -LiteralPath $directory | Should -BeTrue
            }
            Assert-MockCalled New-InitiateGitRepo -Times 1 -ParameterFilter {$DirectoryPath -eq $paths.Project}
        }
    }

    It 'Initialize-NovaModuleScaffold reports an existing project path' {
        InModuleScope $script:moduleName {
            $paths = [pscustomobject]@{
                Project = Join-Path $TestDrive 'ExistingProject'
                Src = Join-Path $TestDrive 'ExistingProject/src'
                Private = Join-Path $TestDrive 'ExistingProject/src/private'
                Public = Join-Path $TestDrive 'ExistingProject/src/public'
                Resources = Join-Path $TestDrive 'ExistingProject/src/resources'
                Classes = Join-Path $TestDrive 'ExistingProject/src/classes'
                Tests = Join-Path $TestDrive 'ExistingProject/tests'
            }
            $null = New-Item -ItemType Directory -Path $paths.Project -Force
            Mock Write-Message {}
            Mock New-Item {}
            Mock New-InitiateGitRepo {}

            {
                Initialize-NovaModuleScaffold -Answer @{EnablePester = 'No'; EnableGit = 'No'} -Paths $paths
            } | Should -Throw 'Project already exists, aborting'

            Assert-MockCalled New-Item -Times 0
            Assert-MockCalled New-InitiateGitRepo -Times 0
        }
    }

    It 'Write-NovaModuleProjectJson writes project metadata and can omit the Pester section' {
        InModuleScope $script:moduleName {
            $projectJsonPath = Join-Path $TestDrive 'project.json'
            Mock New-Guid {[guid]'11111111-1111-1111-1111-111111111111'}

            Write-NovaModuleProjectJson -Answer @{
                ProjectName = 'NovaJson'
                Description = 'Generated project'
                Version = '2.3.4'
                Author = 'Test Author'
                PowerShellHostVersion = '7.4'
                EnablePester = 'No'
            } -ProjectJsonFile $projectJsonPath

            $project = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
            $project.ProjectName | Should -Be 'NovaJson'
            $project.Description | Should -Be 'Generated project'
            $project.Version | Should -Be '2.3.4'
            $project.CopyResourcesToModuleRoot | Should -BeFalse
            $project.Manifest.Author | Should -Be 'Test Author'
            $project.Manifest.PowerShellHostVersion | Should -Be '7.4'
            $project.Manifest.GUID | Should -Be '11111111-1111-1111-1111-111111111111'
            $project.ContainsKey('Pester') | Should -BeFalse
        }
    }

    It 'New-NovaModule creates a scaffolded project when confirmed' {
        InModuleScope $script:moduleName {
            $answer = @{
                ProjectName = 'NovaScaffold'
                Description = 'Scaffolded module'
                Version = '1.0.0'
                Author = 'Tester'
                PowerShellHostVersion = '7.4'
                EnableGit = 'No'
                EnablePester = 'Yes'
            }
            Mock Read-NovaModuleAnswerSet {$answer}
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            New-NovaModule -Path $TestDrive -Confirm:$false

            $projectRoot = Join-Path $TestDrive 'NovaScaffold'
            Test-Path -LiteralPath (Join-Path $projectRoot 'project.json') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'src/public') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'tests') | Should -BeTrue
        }
    }

    It 'New-NovaModule reports invalid paths and skips initialization on WhatIf' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false}
            Mock Get-NovaModuleQuestionSet {@{ProjectName = @{}}}
            Mock Read-NovaModuleAnswerSet {@{ProjectName = 'NovaDryRun'}}
            Mock Get-NovaModuleScaffoldLayout {
                [pscustomobject]@{
                    Project = '/tmp/NovaDryRun'
                    ProjectJsonFile = '/tmp/NovaDryRun/project.json'
                }
            }
            Mock Initialize-NovaModuleScaffold {}
            Mock Write-NovaModuleProjectJson {}

            {New-NovaModule -Path '/tmp/does-not-exist' -WhatIf} | Should -Throw 'Not a valid path'

            Assert-MockCalled Initialize-NovaModuleScaffold -Times 0
            Assert-MockCalled Write-NovaModuleProjectJson -Times 0
        }
    }

    It 'Read-NovaModuleAnswerSet rejects invalid module names with a terminating error' {
        InModuleScope $script:moduleName {
            Mock Read-AwesomeHost {'invalid name!'}

            {
                Read-NovaModuleAnswerSet -Questions @{ProjectName = @{Prompt = 'Name?'}}
            } | Should -Throw 'Module name is invalid*'
        }
    }

    It 'Invoke-NovaCli dispatches the remaining public command branches' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {'info-value'} -ParameterFilter {-not $Version}
            Mock Invoke-NovaBuild {'build-value'}
            Mock Test-NovaBuild {'test-value'}
            Mock New-NovaModule {
                param([string]$Path)
                if ( $PSBoundParameters.ContainsKey('Path')) {
                    return "init:$Path"
                }

                return 'init-default'
            }
            Mock Update-NovaModuleVersion {'bump-value'}
            Mock Invoke-NovaRelease {$PublishOption}

            Invoke-NovaCli info | Should -Be 'info-value'
            Invoke-NovaCli build | Should -Be 'build-value'
            Invoke-NovaCli test | Should -Be 'test-value'
            Invoke-NovaCli init | Should -Be 'init-default'
            Invoke-NovaCli -Command init -Arguments @('/tmp/demo') | Should -Be 'init:/tmp/demo'
            Invoke-NovaCli bump | Should -Be 'bump-value'
            (Invoke-NovaCli release --repository PSGallery --apikey key123).Repository | Should -Be 'PSGallery'
        }
    }

    It 'ConvertFrom-NovaCliArgument parses local, path, and api key options' {
        InModuleScope $script:moduleName {
            $options = ConvertFrom-NovaCliArgument -Arguments @('--local', '--path', '/tmp/modules', '--apikey', 'secret')

            $options.Local | Should -BeTrue
            $options.ModuleDirectoryPath | Should -Be '/tmp/modules'
            $options.ApiKey | Should -Be 'secret'
        }
    }

    It 'ConvertFrom-NovaCliArgument reports missing values for repository, path, and api key' {
        InModuleScope $script:moduleName {
            {ConvertFrom-NovaCliArgument -Arguments @('--repository')} | Should -Throw 'Missing value for --repository'
            {ConvertFrom-NovaCliArgument -Arguments @('--path')} | Should -Throw 'Missing value for --path'
            {ConvertFrom-NovaCliArgument -Arguments @('--apikey')} | Should -Throw 'Missing value for --apikey'
        }
    }

    It 'Get-NovaCliInstallDirectory uses the destination when provided and HOME otherwise' {
        InModuleScope $script:moduleName {
            $custom = Get-NovaCliInstallDirectory -DestinationDirectory "$TestDrive/custom-bin"
            $custom | Should -Be ([System.IO.Path]::GetFullPath("$TestDrive/custom-bin"))

            $originalHome = $HOME
            try {
                $HOME = $TestDrive
                Get-NovaCliInstallDirectory | Should -Be ([System.IO.Path]::Join($TestDrive, '.local', 'bin'))
                $HOME = ''
                {Get-NovaCliInstallDirectory} | Should -Throw 'HOME environment variable is not set*'
            }
            finally {
                $HOME = $originalHome
            }
        }
    }

    It 'Get-NovaCliLauncherPath reports missing file-backed commands and missing launcher files' {
        InModuleScope $script:moduleName {
            Mock Get-Command {
                [pscustomobject]@{
                    ScriptBlock = [pscustomobject]@{File = $null}
                }
            }
            {Get-NovaCliLauncherPath} | Should -Throw 'Install-NovaCli must be loaded from a file-backed module.'

            Mock Get-Command {
                [pscustomobject]@{
                    ScriptBlock = [pscustomobject]@{File = '/tmp/public/InstallNovaCli.ps1'}
                }
            }
            Mock Test-Path {$false}
            {Get-NovaCliLauncherPath} | Should -Throw 'Nova CLI launcher not found*'
        }
    }

    It 'Test-NovaCliDirectoryOnPath returns true when the directory is present' {
        InModuleScope $script:moduleName {
            $originalPath = $env:PATH
            $separator = [string][System.IO.Path]::PathSeparator
            $targetDirectory = [System.IO.Path]::GetFullPath($TestDrive)

            try {
                $env:PATH = "/tmp/other${separator}$targetDirectory${separator}/tmp/else"
                Test-NovaCliDirectoryOnPath -Directory $TestDrive | Should -BeTrue
            }
            finally {
                $env:PATH = $originalPath
            }
        }
    }

    It 'Set-NovaCliExecutablePermission throws when chmod fails' {
        InModuleScope $script:moduleName {
            if ($IsWindows) {
                Set-NovaCliExecutablePermission -Path 'C:\temp\nova' -Confirm:$false
                return
            }

            {Set-NovaCliExecutablePermission -Path (Join-Path $TestDrive 'missing-nova') -Confirm:$false} | Should -Throw 'Failed to make nova launcher executable*'
        }
    }

    It 'Write-Message forwards text and color to Write-Host' {
        InModuleScope $script:moduleName {
            Mock Write-Host {}

            'hello' | Write-Message -color Green

            Assert-MockCalled Write-Host -Times 1 -ParameterFilter {$Object -eq 'hello' -and $ForegroundColor -eq 'Green'}
        }
    }

    It 'Build-Help skips when no markdown files exist' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {[pscustomobject]@{DocsDir = '/tmp/docs'}}
            Mock Get-ChildItem {@()}
            Mock Get-Module {}

            Build-Help

            Assert-MockCalled Get-Module -Times 0
        }
    }

    It 'Build-Help throws when PlatyPS is unavailable and docs exist' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {[pscustomobject]@{DocsDir = '/tmp/docs'}}
            Mock Get-ChildItem {@([pscustomobject]@{FullName = '/tmp/docs/Invoke-NovaBuild.md'})}
            Mock Get-Module {$null}

            {Build-Help} | Should -Throw 'The module Microsoft.PowerShell.PlatyPS must be installed*'
        }
    }

    It 'Build-Help imports markdown help and renames the generated locale folder' {
        InModuleScope $script:moduleName {
            $docPath = Join-Path $TestDrive 'Invoke-NovaBuild.md'
            Set-Content -LiteralPath $docPath -Value "---`nLocale: da-DK`n---"

            Mock Get-NovaProjectInfo {
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

    It 'Build-Manifest includes resource paths and prerelease manifest metadata' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{
                PublicDir = '/tmp/public'
                ResourcesDir = '/tmp/resources'
                CopyResourcesToModuleRoot = $false
                Manifest = [ordered]@{Author = 'Tester'; CompanyName = 'Nova'}
                Version = '1.2.3-preview'
                Description = 'Example'
                ProjectName = 'NovaModuleTools'
                ManifestFilePSD1 = '/tmp/NovaModuleTools.psd1'
            }
            Mock Get-NovaProjectInfo {$projectInfo}
            Mock Get-ChildItem {@([pscustomobject]@{FullName = '/tmp/public/Get-Thing.ps1'})} -ParameterFilter {$Path -eq '/tmp/public'}
            Mock Get-ChildItem {@([pscustomobject]@{Name = 'Nova.Format.ps1xml'})} -ParameterFilter {$Filter -eq '*Format.ps1xml'}
            Mock Get-ChildItem {@([pscustomobject]@{Name = 'Nova.Types.ps1xml'})} -ParameterFilter {$Filter -eq '*Types.ps1xml'}
            Mock Get-FunctionNameFromFile {'Get-Thing'}
            Mock Get-AliasInFunctionFromFile {'gt'}
            Mock Assert-ManifestSchema {}
            Mock New-ModuleManifest {}

            Build-Manifest

            Assert-MockCalled New-ModuleManifest -Times 1 -ParameterFilter {
                $Path -eq '/tmp/NovaModuleTools.psd1' -and
                        $FunctionsToExport -eq @('Get-Thing') -and
                        $AliasesToExport -eq @('gt') -and
                        $FormatsToProcess -eq @('resources/Nova.Format.ps1xml') -and
                        $TypesToProcess -eq @('resources/Nova.Types.ps1xml') -and
                        $Prerelease -eq 'preview' -and
                        $Author -eq 'Tester' -and
                        $CompanyName -eq 'Nova'
            }
        }
    }

    It 'Build-Manifest reports manifest creation failures' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {
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

            {Build-Manifest} | Should -Throw 'Failed to create Manifest*'
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

    It 'Get-NovaVersionPreReleaseLabel returns preview, stable, or the existing prerelease label' {
        InModuleScope $script:moduleName {
            Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3-preview') -PreviewRelease | Should -Be 'preview'
            $stable = Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3-preview') -StableRelease
            $stable | Should -BeNullOrEmpty
            Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3-preview') | Should -Be 'preview'
        }
    }

    It 'Set-NovaModuleVersion writes a new semantic version to project.json' {
        InModuleScope $script:moduleName {
            $projectJsonPath = Join-Path $TestDrive 'project.json'
            Set-Content -LiteralPath $projectJsonPath -Value '{"Version":"1.2.3"}' -Encoding utf8
            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectJSON = $projectJsonPath}}
            Mock Write-Host {}

            Set-NovaModuleVersion -Label Minor -PreviewRelease -Confirm:$false

            (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).Version | Should -Be '1.3.0-preview'
        }
    }

    It 'Publish-NovaBuiltModuleToRepository uses the PSGallery fallback api key when needed' {
        InModuleScope $script:moduleName {
            $originalApiKey = $env:PSGALLERY_API
            try {
                $env:PSGALLERY_API = 'gallery-secret'
                Mock Publish-PSResource {}

                Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist'}) -Repository PSGallery

                Assert-MockCalled Publish-PSResource -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Repository -eq 'PSGallery' -and $ApiKey -eq 'gallery-secret' -and $Verbose}
            }
            finally {
                $env:PSGALLERY_API = $originalApiKey
            }
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
            {Publish-NovaBuiltModule -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/missing'; ProjectName = 'Nova'})} | Should -Throw 'Dist folder is empty*'

            Mock Get-LocalModulePath {'/tmp/local-modules'}
            Resolve-NovaLocalPublishPath -ModuleDirectoryPath '/tmp/custom' | Should -Be '/tmp/custom'
            Resolve-NovaLocalPublishPath | Should -Be '/tmp/local-modules'
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

    It 'Get-ResourceFilePath falls back cleanly and throws when no candidate exists' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {throw 'not a project'}
            Mock Test-Path {$false}

            {Get-ResourceFilePath -FileName 'missing.json'} | Should -Throw 'Resource file not found: missing.json*'
        }
    }
}








