BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:novaModuleToolsCiScriptPath = Join-Path $script:repoRoot 'scripts/build/ci/Invoke-NovaModuleToolsCI.ps1'

    function Invoke-NovaModuleToolsCIRunner {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$RunnerContent
        )

        $runnerPath = Join-Path $TestDrive 'Run-Invoke-NovaModuleToolsCI.ps1'
        $content = @"
$RunnerContent

if (`$null -ne `$LASTEXITCODE) {
    exit `$LASTEXITCODE
}

if (`$?) {
    exit 0
}

exit 1
"@
        Set-Content -LiteralPath $runnerPath -Value $content -Encoding utf8

        $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = @($output)
        }
    }
}

Describe 'Invoke-NovaModuleToolsCI' {
    It 'runs Invoke-NovaTest before Test-NovaBuild, forwards ExcludeTag, and copies both NUnit artifacts' {
        $projectRoot = Join-Path $TestDrive 'project'
        $outputDirectory = Join-Path $TestDrive 'artifacts-out'
        $callLogPath = Join-Path $TestDrive 'call-log.txt'
        $commandLogPath = Join-Path $TestDrive 'commands.txt'
        $unitResultPath = Join-Path $projectRoot 'artifacts/UnitTestResults.xml'
        $integrationResultPath = Join-Path $projectRoot 'artifacts/TestResults.xml'

        New-Item -ItemType Directory -Path (Split-Path -Parent $unitResultPath) -Force | Out-Null
        Set-Content -LiteralPath $unitResultPath -Value '<unit-test-results />' -Encoding utf8
        Set-Content -LiteralPath $integrationResultPath -Value '<integration-test-results />' -Encoding utf8

        $runnerContent = @"
function Import-Module {
    [CmdletBinding()]
    param(
        [string]`$Name,
        [switch]`$Force
    )
}

function Invoke-NovaBuild {}

function Get-NovaProjectInfo {
    return [pscustomobject]@{
        OutputModuleDir = '$projectRoot/dist/NovaModuleTools'
        ProjectName = 'NovaModuleTools'
        ProjectRoot = '$projectRoot'
    }
}

function pwsh {
    [CmdletBinding()]
    param(
        [switch]`$NoLogo,
        [switch]`$NoProfile,
        [string]`$Command
    )

    Add-Content -LiteralPath '$commandLogPath' -Value `$Command
    if (`$Command -match 'Invoke-NovaTest') {
        Add-Content -LiteralPath '$callLogPath' -Value 'Invoke-NovaTest'
    }

    if (`$Command -match 'Test-NovaBuild') {
        Add-Content -LiteralPath '$callLogPath' -Value 'Test-NovaBuild'
    }

    `$global:LASTEXITCODE = 0
}

& '$script:novaModuleToolsCiScriptPath' -OutputDirectory '$outputDirectory' -ExcludeTag 'slow','integration'
"@
        $result = Invoke-NovaModuleToolsCIRunner -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        (Get-Content -LiteralPath $callLogPath) | Should -Be @('Invoke-NovaTest', 'Test-NovaBuild')
        $commands = Get-Content -LiteralPath $commandLogPath
        $commands | Should -HaveCount 2
        $commands[0] | Should -Match "Import-Module '.*/dist/NovaModuleTools/NovaModuleTools\.psd1' -Force -ErrorAction Stop; Invoke-NovaTest -ExcludeTagFilter @\('slow', 'integration'\)"
        $commands[1] | Should -Match "Import-Module '.*/dist/NovaModuleTools/NovaModuleTools\.psd1' -Force -ErrorAction Stop; Test-NovaBuild -ExcludeTagFilter @\('slow', 'integration'\)"
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'novamoduletools-unit-nunit.xml') -Raw).Trim() | Should -Be '<unit-test-results />'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'novamoduletools-integration-nunit.xml') -Raw).Trim() | Should -Be '<integration-test-results />'
    }

    It 'returns a non-zero exit code after copying available artifacts when a test command fails' {
        $projectRoot = Join-Path $TestDrive 'project-failure'
        $outputDirectory = Join-Path $TestDrive 'artifacts-out-failure'
        $unitResultPath = Join-Path $projectRoot 'artifacts/UnitTestResults.xml'

        New-Item -ItemType Directory -Path (Split-Path -Parent $unitResultPath) -Force | Out-Null
        Set-Content -LiteralPath $unitResultPath -Value '<failed-unit-test-results />' -Encoding utf8

        $runnerContent = @"
function Import-Module {
    [CmdletBinding()]
    param(
        [string]`$Name,
        [switch]`$Force
    )
}

function Invoke-NovaBuild {}

function Get-NovaProjectInfo {
    return [pscustomobject]@{
        OutputModuleDir = '$projectRoot/dist/NovaModuleTools'
        ProjectName = 'NovaModuleTools'
        ProjectRoot = '$projectRoot'
    }
}

function pwsh {
    [CmdletBinding()]
    param(
        [switch]`$NoLogo,
        [switch]`$NoProfile,
        [string]`$Command
    )

    if (`$Command -match 'Invoke-NovaTest') {
        `$global:LASTEXITCODE = 1
        return
    }

    `$global:LASTEXITCODE = 0
}

& '$script:novaModuleToolsCiScriptPath' -OutputDirectory '$outputDirectory'
"@
        $result = Invoke-NovaModuleToolsCIRunner -RunnerContent $runnerContent
        $outputText = $result.Output -join [Environment]::NewLine

        $result.ExitCode | Should -Be 1
        $outputText | Should -Match 'Nova test workflow failed: Validation command failed: .*Invoke-NovaTest'
        (Get-Content -LiteralPath (Join-Path $outputDirectory 'novamoduletools-unit-nunit.xml') -Raw).Trim() | Should -Be '<failed-unit-test-results />'
        Test-Path -LiteralPath (Join-Path $outputDirectory 'novamoduletools-integration-nunit.xml') | Should -BeFalse
    }
}
