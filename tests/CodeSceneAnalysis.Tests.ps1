BeforeAll {
    $codeSceneAnalysisScriptPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'Invoke-CodeSceneAnalysis.ps1')).Path

    function Invoke-CodeSceneAnalysisTestScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$RunnerContent
        )

        $runnerPath = Join-Path $TestDrive 'Run-CodeSceneAnalysisTest.ps1'
        Set-Content -LiteralPath $runnerPath -Value $RunnerContent -Encoding utf8

        $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = @($output)
        }
    }

    function New-CodeSceneCoverageUploadRunnerContent {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][pscustomobject]$Config
        )

        $setLocationCommand = ''
        if ($Config.WorkingDirectory) {
            $setLocationCommand = "Set-Location '$($Config.WorkingDirectory)'"
        }

        return @"
function cs-coverage {
    param([Parameter(ValueFromRemainingArguments = `$true)][string[]]`$ArgumentList)

    Add-Content -LiteralPath '$($Config.UploadLogPath)' -Value (`$ArgumentList -join ' ') -Encoding utf8
    `$global:LASTEXITCODE = 0
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')
$setLocationCommand

& '$codeSceneAnalysisScriptPath' $($Config.Invocation)
"@
    }
}

Describe 'Invoke-CodeSceneAnalysis' {
    It 'supports trigger-only runs when CoveragePath is omitted' {
        $requestLogPath = Join-Path $TestDrive 'codescene-request.txt'
        $runnerContent = @"
function Invoke-WebRequest {
    param(
        [string]`$Uri,
        [string]`$Method,
        [hashtable]`$Headers,
        [switch]`$SkipHttpErrorCheck
    )

    Set-Content -LiteralPath '$requestLogPath' -Value "`$Method|`$Uri|`$( `$Headers.Authorization )" -Encoding utf8
    return [pscustomobject]@{
        StatusCode = 202
        Content = '{"queued":true}'
    }
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')

& '$codeSceneAnalysisScriptPath' -TriggerAnalysis
"@

        $result = Invoke-CodeSceneAnalysisTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        (Get-Content -LiteralPath $requestLogPath -Raw) | Should -BeLike 'Post|https://codescene.example.test/v2/projects/123/run-analysis|Bearer token*'
    }

    It 'fails clearly when CodeScene rejects the analysis trigger because the project owner OAuth token is invalid' {
        $runnerContent = @"
function Invoke-WebRequest {
    param(
        [string]`$Uri,
        [string]`$Method,
        [hashtable]`$Headers,
        [switch]`$SkipHttpErrorCheck
    )

    return [pscustomobject]@{
        StatusCode = 400
        Content = '{"error":"OAuth token of project owner invalid"}'
    }
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')

& '$codeSceneAnalysisScriptPath' -TriggerAnalysis
"@

        $result = Invoke-CodeSceneAnalysisTestScript -RunnerContent $runnerContent
        $outputText = ($result.Output -join [Environment]::NewLine)

        $result.ExitCode | Should -Not -Be 0
        $outputText | Should -Match 'project owner'
        $outputText | Should -Match '(?s)separate from.*CS_ACCESS_TOKEN'
    }

    It 'uploads coverage for <Name>' -ForEach @(
        @{ Name = 'an explicit coverage path'; Mode = 'Explicit'; UploadLogName = 'cs-coverage-upload.txt' }
        @{ Name = 'the discovered artifacts coverage file'; Mode = 'Discovered'; UploadLogName = 'cs-coverage-upload-discovered.txt' }
    ) {
        $artifactsDir = Join-Path $TestDrive 'artifacts'
        $coveragePath = Join-Path $TestDrive 'coverage.xml'
        $workingDirectory = $null
        $invocation = "-CoveragePath '$coveragePath'"
        if ($Mode -eq 'Discovered') {
            New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
            $coveragePath = Join-Path $artifactsDir 'coverage.xml'
            $workingDirectory = $TestDrive
            $invocation = '-UploadCoverage'
        }

        $uploadLogPath = Join-Path $TestDrive $UploadLogName
        Set-Content -LiteralPath $coveragePath -Value '<report><counter type="BRANCH" missed="1" covered="1" /></report>' -Encoding utf8

        $runnerContent = New-CodeSceneCoverageUploadRunnerContent -Config ([pscustomobject]@{
            CoveragePath = $coveragePath
            Invocation = $invocation
            UploadLogPath = $uploadLogPath
            WorkingDirectory = $workingDirectory
        })
        $result = Invoke-CodeSceneAnalysisTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        $uploadLog = Get-Content -LiteralPath $uploadLogPath -Raw
        $uploadLog | Should -BeLike "upload --format jacoco --metric line-coverage $coveragePath*"
        $uploadLog | Should -Match 'upload --format jacoco --metric branch-coverage'
    }

    It 'fails clearly when UploadCoverage is requested but no JaCoCo artifact exists' {
        $emptyWorkingDir = Join-Path $TestDrive 'no-coverage-artifacts'
        New-Item -ItemType Directory -Path $emptyWorkingDir -Force | Out-Null

        $runnerContent = @"
function cs-coverage {
    throw 'cs-coverage should not be called when no coverage artifact exists.'
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')
Set-Location '$emptyWorkingDir'

& '$codeSceneAnalysisScriptPath' -UploadCoverage
"@

        $result = Invoke-CodeSceneAnalysisTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Not -Be 0
        ($result.Output -join [Environment]::NewLine) | Should -Match 'No JaCoCo coverage file was found at'
    }

    It 'normalizes Pester JaCoCo sourcefile paths so package + sourcefile resolves to repo files' {
        $coverageDir = Join-Path $TestDrive 'pester-jacoco'
        New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
        $coveragePath = Join-Path $coverageDir 'coverage.xml'
        Set-Content -LiteralPath $coveragePath -Encoding utf8 -Value @'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<report name="Pester">
  <package name="src/private/build">
    <class name="src/private/build/Foo" sourcefilename="private/build/Foo.ps1" />
    <sourcefile name="private/build/Foo.ps1" />
  </package>
</report>
'@

        $runnerContent = @"
function cs-coverage {
    `$global:LASTEXITCODE = 0
    return
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')

& '$codeSceneAnalysisScriptPath' -CoveragePath '$coveragePath'
"@

        $result = Invoke-CodeSceneAnalysisTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)

        [xml]$rewritten = Get-Content -LiteralPath $coveragePath -Raw
        $class = $rewritten.SelectSingleNode('//class[@sourcefilename]')
        $class.GetAttribute('sourcefilename') | Should -Be 'Foo.ps1'
        $sourcefile = $rewritten.SelectSingleNode('//sourcefile[@name]')
        $sourcefile.GetAttribute('name') | Should -Be 'Foo.ps1'
    }

    It 'skips branch-coverage upload when the JaCoCo report has no BRANCH counters' {
        $coveragePath = Join-Path $TestDrive 'coverage-no-branch.xml'
        $uploadLogPath = Join-Path $TestDrive 'cs-coverage-upload-no-branch.txt'
        Set-Content -LiteralPath $coveragePath -Value '<report><counter type="LINE" missed="0" covered="1" /></report>' -Encoding utf8

        $runnerContent = @"
function cs-coverage {
    param([Parameter(ValueFromRemainingArguments = `$true)][string[]]`$ArgumentList)

    Add-Content -LiteralPath '$uploadLogPath' -Value (`$ArgumentList -join ' ') -Encoding utf8
    `$global:LASTEXITCODE = 0
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')

& '$codeSceneAnalysisScriptPath' -CoveragePath '$coveragePath'
"@

        $result = Invoke-CodeSceneAnalysisTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        $uploadLog = Get-Content -LiteralPath $uploadLogPath -Raw
        $uploadLog | Should -Match 'upload --format jacoco --metric line-coverage'
        $uploadLog | Should -Not -Match 'branch-coverage'
        ($result.Output -join [Environment]::NewLine) | Should -Match 'Skipping branch-coverage upload'
    }
}
