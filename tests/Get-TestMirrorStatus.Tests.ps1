BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:mirrorStatusScriptPath = Join-Path $script:repoRoot 'scripts/build/Get-TestMirrorStatus.ps1'

    function Invoke-GetTestMirrorStatusRunner {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$RunnerContent
        )

        $runnerPath = Join-Path $TestDrive 'Run-GetTestMirrorStatus.ps1'
        Set-Content -LiteralPath $runnerPath -Value $RunnerContent -Encoding utf8

        $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = @($output)
        }
    }
}

Describe 'Get-TestMirrorStatus' {
    It 'maps nested private source files to mirrored test paths and marks missing tests' {
        $projectRoot = Join-Path $TestDrive 'project'
        $jsonPath = Join-Path $TestDrive 'mirror-status.json'

        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src/public') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src/private/build/manifest') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src/private/quality/duplicates') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src/classes') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'tests/public') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'tests/private/quality/duplicates') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'tests/classes') -Force | Out-Null

        Set-Content -LiteralPath (Join-Path $projectRoot 'src/public/Invoke-Thing.ps1') -Value 'function Invoke-Thing {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'src/private/build/manifest/Get-Thing.ps1') -Value 'function Get-Thing {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'src/private/quality/duplicates/Test-Thing.ps1') -Value 'function Test-Thing {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'src/classes/Thing.ps1') -Value 'class Thing {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'tests/public/Invoke-Thing.Tests.ps1') -Value 'Describe "Invoke-Thing" {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'tests/private/quality/duplicates/Test-Thing.Tests.ps1') -Value 'Describe "Test-Thing" {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'tests/classes/Thing.Tests.ps1') -Value 'Describe "Thing" {}' -Encoding utf8

        $runnerContent = @"
`$entries = & '$script:mirrorStatusScriptPath' -ProjectRoot '$projectRoot' -Quiet
@(`$entries) | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath '$jsonPath' -Encoding utf8
"@
        $result = Invoke-GetTestMirrorStatusRunner -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        $entries = @(Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json)

        $entries.Count | Should -Be 4

        $nestedPrivateEntry = $entries | Where-Object SourcePath -eq 'src/private/quality/duplicates/Test-Thing.ps1'
        $nestedPrivateEntry.TestPath | Should -Be 'tests/private/quality/duplicates/Test-Thing.Tests.ps1'
        $nestedPrivateEntry.Mirrored | Should -BeTrue

        $missingEntry = $entries | Where-Object SourcePath -eq 'src/private/build/manifest/Get-Thing.ps1'
        $missingEntry.TestPath | Should -Be 'tests/private/build/manifest/Get-Thing.Tests.ps1'
        $missingEntry.Mirrored | Should -BeFalse
    }

    It 'prints summary counts and missing source paths when Quiet is not set' {
        $projectRoot = Join-Path $TestDrive 'project-report'

        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src/public') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'src/private/build') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $projectRoot 'tests/public') -Force | Out-Null

        Set-Content -LiteralPath (Join-Path $projectRoot 'src/public/Invoke-Thing.ps1') -Value 'function Invoke-Thing {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'src/private/build/Get-Thing.ps1') -Value 'function Get-Thing {}' -Encoding utf8
        Set-Content -LiteralPath (Join-Path $projectRoot 'tests/public/Invoke-Thing.Tests.ps1') -Value 'Describe "Invoke-Thing" {}' -Encoding utf8

        $runnerContent = "& '$script:mirrorStatusScriptPath' -ProjectRoot '$projectRoot' | Out-Null"
        $result = Invoke-GetTestMirrorStatusRunner -RunnerContent $runnerContent
        $outputText = $result.Output -join [Environment]::NewLine

        $result.ExitCode | Should -Be 0 -Because $outputText
        $outputText | Should -Match 'Source files scanned : 2'
        $outputText | Should -Match 'Mirrored test files  : 1'
        $outputText | Should -Match 'Missing mirrored test: 1'
        $outputText | Should -Match 'src/private/build/Get-Thing\.ps1 -> tests/private/build/Get-Thing\.Tests\.ps1'
    }
}
