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

Describe 'Coverage for remaining manifest, JSON, and help-locale helpers' {
    It 'Format-NovaCliVersionString combines the component name and version' {
        InModuleScope $script:moduleName {
            Format-NovaCliVersionString -Name 'NovaModuleTools' -Version '1.9.10' | Should -Be 'NovaModuleTools 1.9.10'
        }
    }

    It 'Format-NovaCliVersionString keeps prerelease labels in the provided version string' {
        InModuleScope $script:moduleName {
            Format-NovaCliVersionString -Name 'NovaModuleTools' -Version '1.11.1-preview' | Should -Be 'NovaModuleTools 1.11.1-preview'
        }
    }

    It 'Get-LocalModulePathEntryList ignores blank PSModulePath segments' {
        $originalModulePath = $env:PSModulePath
        $separator = [IO.Path]::PathSeparator

        try {
            $env:PSModulePath = "/tmp/modules$separator$separator /tmp/alt-modules "

            InModuleScope $script:moduleName {
                Get-LocalModulePathEntryList | Should -Be @('/tmp/modules', '/tmp/alt-modules')
            }
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }
    }

    It 'Test-ProjectSchema validates the Build schema' {
        InModuleScope $script:moduleName {
            Mock Get-ResourceFilePath {
                if ($FileName -eq 'Schema-Build.json') {
                    return '/tmp/build-schema.json'
                }

                return '/tmp/pester-schema.json'
            }
            Mock Get-Content {
                if ($Path -eq '/tmp/build-schema.json') {
                    return '{"title":"build"}'
                }

                return '{"title":"pester"}'
            }
            Mock Test-Json {$true}

            Test-ProjectSchema -Schema Build | Should -BeTrue

            Assert-MockCalled Test-Json -Times 1 -ParameterFilter {
                $Path -eq 'project.json' -and $Schema -eq '{"title":"build"}'
            }
        }
    }

    It 'Get-AliasInFunctionFromFile returns aliases declared on the function' {
        $filePath = Join-Path $script:repoRoot 'src/public/InvokeNovaCli.ps1'

        InModuleScope $script:moduleName -Parameters @{FilePath = $filePath} {
            param($FilePath)

            @(Get-AliasInFunctionFromFile -filePath $FilePath) | Should -Be @('nova')
        }
    }

    It 'Get-AliasInFunctionFromFile returns nothing when the file cannot be parsed' {
        InModuleScope $script:moduleName {
            $result = Get-AliasInFunctionFromFile -filePath (Join-Path $TestDrive 'missing.ps1')

            $result | Should -BeNullOrEmpty
        }
    }

    It 'Get-OrderedScriptFileForDirectory returns an empty list when the directory is missing' {
        InModuleScope $script:moduleName {
            @(Get-OrderedScriptFileForDirectory -Directory (Join-Path $TestDrive 'missing-dir') -ProjectRoot $TestDrive -Recurse $false) | Should -Be @()
        }
    }

    It 'Get-FunctionNameFromFile returns every function name in the file' {
        $filePath = Join-Path $TestDrive 'Functions.ps1'
        @'
function Get-First {
}

function Get-Second {
}
'@ | Set-Content -LiteralPath $filePath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{FilePath = $filePath} {
            param($FilePath)

            @(Get-FunctionNameFromFile -filePath $FilePath) | Should -Be @('Get-First', 'Get-Second')
        }
    }

    It 'Get-FunctionNameFromFile returns an empty string when the file cannot be read' {
        InModuleScope $script:moduleName {
            Get-FunctionNameFromFile -filePath (Join-Path $TestDrive 'missing.ps1') | Should -Be ''
        }
    }

    It 'Read-ProjectJsonData returns a hashtable for a valid project object' {
        $projectJsonPath = Join-Path $TestDrive 'project.json'
        '{"ProjectName":"NovaModuleTools","Version":"1.2.3"}' | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{ProjectJsonPath = $projectJsonPath} {
            param($ProjectJsonPath)

            $result = Read-ProjectJsonData -ProjectJsonPath $ProjectJsonPath

            $result | Should -BeOfType 'hashtable'
            $result.ProjectName | Should -Be 'NovaModuleTools'
            $result.Version | Should -Be '1.2.3'
        }
    }

    It 'Read-ProjectJsonData throws when project.json is <Name>' -ForEach @(
        @{
            Name = 'empty'
            FileName = 'empty-project.json'
            Content = ''
            ExpectedMessage = 'project.json is empty*'
        }
        @{
            Name = 'not valid JSON'
            FileName = 'invalid-project.json'
            Content = '{ invalid json }'
            ExpectedMessage = 'project.json is not valid JSON*'
        }
        @{
            Name = 'not a top-level object'
            FileName = 'array-project.json'
            Content = '[1,2,3]'
            ExpectedMessage = 'project.json must contain a top-level JSON object*'
        }
    ) {
        $projectJsonPath = Join-Path $TestDrive $_.FileName
        $_.Content | Set-Content -LiteralPath $projectJsonPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{ProjectJsonPath = $projectJsonPath; ExpectedMessage = $_.ExpectedMessage} {
            param($ProjectJsonPath, $ExpectedMessage)

            {Read-ProjectJsonData -ProjectJsonPath $ProjectJsonPath} | Should -Throw $ExpectedMessage
        }
    }

    It 'Get-NovaHelpLocale defaults to en-US when docs metadata has no locale' {
        $docPath = Join-Path $TestDrive 'No-Locale.md'
        @'
---
title: Test-Help
---
'@ | Set-Content -LiteralPath $docPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{HelpFile = (Get-Item -LiteralPath $docPath)} {
            param($HelpFile)

            Get-NovaHelpLocale -HelpMarkdownFiles $HelpFile | Should -Be 'en-US'
        }
    }

    It 'Get-NovaHelpLocale throws when docs metadata contains conflicting locales' {
        $firstDocPath = Join-Path $TestDrive 'First.md'
        $secondDocPath = Join-Path $TestDrive 'Second.md'
        @'
---
Locale: da-DK
---
'@ | Set-Content -LiteralPath $firstDocPath -Encoding utf8
        @'
---
Locale: en-US
---
'@ | Set-Content -LiteralPath $secondDocPath -Encoding utf8

        InModuleScope $script:moduleName -Parameters @{FirstDocPath = $firstDocPath; SecondDocPath = $secondDocPath} {
            param($FirstDocPath, $SecondDocPath)

            $helpFiles = @(
                Get-Item -LiteralPath $FirstDocPath
                Get-Item -LiteralPath $SecondDocPath
            )

            {Get-NovaHelpLocale -HelpMarkdownFiles $helpFiles} | Should -Throw 'Multiple help locales found in docs metadata*'
        }
    }
}
