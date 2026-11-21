BeforeAll {
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
    $script:wrapperPath = Join-Path $script:repoRoot 'scripts/build/Invoke-ScriptAnalyzerCI.ps1'

    function New-FakeSharedAnalyzer {
        param([Parameter(Mandatory)][int]$ExitCode)

        $sharedRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $scriptDirectory = Join-Path $sharedRoot 'actions/script-analyzer'
        $null = New-Item -ItemType Directory -Path $scriptDirectory -Force
        $recordPath = Join-Path $sharedRoot 'arguments.json'
        Set-Content -LiteralPath (Join-Path $scriptDirectory 'Invoke-ScriptAnalyzerCI.ps1') -Encoding utf8 -Value @(
            'param([string]$ProjectRoot, [string]$OutputDirectory, [string[]]$AnalysisPath, [string]$RequiredVersion, [string[]]$Severity)'
            "`$PSBoundParameters | ConvertTo-Json | Set-Content -LiteralPath '$recordPath'"
            "exit $ExitCode"
        )
        return [pscustomobject]@{ Root = $sharedRoot; RecordPath = $recordPath }
    }

    function Invoke-AnalyzerWrapper {
        param([Parameter(Mandatory)][AllowEmptyString()][string]$SharedRoot)

        $runnerPath = Join-Path $TestDrive 'Run-AnalyzerWrapper.ps1'
        Set-Content -LiteralPath $runnerPath -Encoding utf8 -Value @(
            "`$env:POWERSHELL_CI_PATH = '$SharedRoot'"
            "& '$script:wrapperPath' -OutputDirectory '$(Join-Path $TestDrive 'artifacts')'"
        )
        $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join [Environment]::NewLine) }
    }
}

Describe 'Invoke-ScriptAnalyzerCI wrapper' {
    It 'delegates to the shared analyzer with the Nova analysis scope' {
        $shared = New-FakeSharedAnalyzer -ExitCode 0

        $result = Invoke-AnalyzerWrapper -SharedRoot $shared.Root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $arguments = Get-Content -LiteralPath $shared.RecordPath -Raw | ConvertFrom-Json
        $arguments.ProjectRoot | Should -Be $script:repoRoot
        $arguments.AnalysisPath | Should -Be @('src', 'scripts', 'run.ps1')
        $arguments.Severity | Should -Be @('Error', 'Warning', 'ParseError')
        $arguments.RequiredVersion | Should -Be '1.25.0'
    }

    It 'fails when the shared analyzer reports findings' {
        $shared = New-FakeSharedAnalyzer -ExitCode 1

        $result = Invoke-AnalyzerWrapper -SharedRoot $shared.Root

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'PSScriptAnalyzer gate failed'
    }

    It 'explains how to provide the shared checkout when it is missing' {
        $result = Invoke-AnalyzerWrapper -SharedRoot (Join-Path $TestDrive 'missing-powershell-ci')

        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'POWERSHELL_CI_PATH'
    }
}
