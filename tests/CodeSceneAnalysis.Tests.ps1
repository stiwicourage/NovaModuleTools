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

    It 'still uploads coverage when CoveragePath is provided' {
        $coveragePath = Join-Path $TestDrive 'coverage.xml'
        $uploadLogPath = Join-Path $TestDrive 'cs-coverage-upload.txt'
        Set-Content -LiteralPath $coveragePath -Value '<report />' -Encoding utf8

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
        $uploadLog | Should -BeLike "upload --format jacoco --metric line-coverage $coveragePath*"
        $uploadLog | Should -Match 'upload --format jacoco --metric branch-coverage'
    }

    It 'uploads coverage from the artifacts folder when UploadCoverage is requested without CoveragePath' {
        $artifactsDir = Join-Path $TestDrive 'artifacts'
        $coveragePath = Join-Path $artifactsDir 'coverage.xml'
        $uploadLogPath = Join-Path $TestDrive 'cs-coverage-upload-discovered.txt'
        New-Item -ItemType Directory -Path $artifactsDir -Force | Out-Null
        Set-Content -LiteralPath $coveragePath -Value '<report />' -Encoding utf8

        $runnerContent = @"
function cs-coverage {
    param([Parameter(ValueFromRemainingArguments = `$true)][string[]]`$ArgumentList)

    Add-Content -LiteralPath '$uploadLogPath' -Value (`$ArgumentList -join ' ') -Encoding utf8
    `$global:LASTEXITCODE = 0
}

[Environment]::SetEnvironmentVariable('CS_URL', 'https://codescene.example.test')
[Environment]::SetEnvironmentVariable('CS_PROJECT_ID', '123')
[Environment]::SetEnvironmentVariable('CS_ACCESS_TOKEN', 'token')
Set-Location '$TestDrive'

& '$codeSceneAnalysisScriptPath' -UploadCoverage
"@

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
}
