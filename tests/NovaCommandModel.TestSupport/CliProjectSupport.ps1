function Initialize-TestNovaCliProjectLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    New-Item -ItemType Directory -Path $ProjectRoot -Force | Out-Null
    foreach ($dir in @('src/public', 'src/private', 'src/classes', 'src/resources', 'tests', 'docs')) {
        New-Item -ItemType Directory -Path (Join-Path $ProjectRoot $dir) -Force | Out-Null
    }
}

function Write-TestNovaCliProjectJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ProjectGuid
    )

    @"
{
  "ProjectName": "$ProjectName",
  "Description": "CLI test project",
  "Version": "0.0.1",
  "CopyResourcesToModuleRoot": false,
  "Manifest": {
    "Author": "Test",
    "PowerShellHostVersion": "7.4",
    "GUID": "$ProjectGuid",
    "Tags": [],
    "ProjectUri": ""
  },
  "Package": {
    "Types": [
      "NuGet"
    ],
    "OutputDirectory": {
      "Path": "artifacts/packages",
      "Clean": true
    }
  },
  "Pester": {
    "TestResult": {
      "Enabled": true,
      "OutputFormat": "NUnitXml"
    },
    "Output": {
      "Verbosity": "Detailed"
    }
  }
}
"@ | Set-Content -LiteralPath (Join-Path $ProjectRoot 'project.json') -Encoding utf8
}

function Write-TestNovaCliPublicFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$FunctionName
    )

    @"
function $FunctionName {
    'ok'
}
"@ | Set-Content -LiteralPath (Join-Path $ProjectRoot "src/public/$FunctionName.ps1") -Encoding utf8
}

function Initialize-TestNovaCliGitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$CommitMessage
    )

    foreach ($command in @(
        @('init'),
        @('config', 'user.name', 'Nova CLI Test'),
        @('config', 'user.email', 'nova-cli-test@example.invalid'),
        @('add', '.'),
        @('-c', 'commit.gpgSign=false', 'commit', '--no-verify', '-m', $CommitMessage, '--quiet')
    )) {
        $null = & git -C $ProjectRoot @command 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Git command failed: git -C $ProjectRoot $( $command -join ' ' )"
        }
    }
}

function Invoke-TestInstalledNovaCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstalledPath,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string[]]$Arguments,
        [hashtable]$EnvironmentVariables = @{}
    )

    $originalEnvironment = @{}
    foreach ($variableName in $EnvironmentVariables.Keys) {
        $originalEnvironment[$variableName] = [System.Environment]::GetEnvironmentVariable($variableName, 'Process')
        [System.Environment]::SetEnvironmentVariable($variableName, [string]$EnvironmentVariables[$variableName], 'Process')
    }

    Push-Location $WorkingDirectory
    try {
        $output = & $InstalledPath @Arguments 2>&1
        return [pscustomobject]@{
            Output = @($output)
            Text = (@($output) -join [Environment]::NewLine)
            ExitCode = $LASTEXITCODE
        }
    }
    finally {
        Pop-Location

        foreach ($variableName in $EnvironmentVariables.Keys) {
            [System.Environment]::SetEnvironmentVariable($variableName, $originalEnvironment[$variableName], 'Process')
        }
    }
}

function Get-TestNovaCliWhatIfResultMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$InstalledPath,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    return @{
        Build = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('build', '--what-if')
        BuildCi = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('build', '--continuous-integration', '--what-if')
        TestShort = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('test', '-w')
        TestLong = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('test', '--what-if')
        Publish = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('publish', '--local', '-w')
        PublishCi = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('publish', '--local', '-i', '-w')
        Bump = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('bump', '-w')
        BumpCi = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('bump', '-i', '-w')
        PreviewBump = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('bump', '--preview', '--what-if')
        ReleaseCi = Invoke-TestInstalledNovaCommand -InstalledPath $InstalledPath -WorkingDirectory $ProjectRoot -Arguments @('release', '--local', '-i', '-w')
    }
}

function Assert-TestNovaCliWhatIfResultMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ResultMap,
        [Parameter(Mandatory)][string]$ProjectJsonPath,
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$TestResultPath
    )

    foreach ($resultName in $ResultMap.Keys) {
        $ResultMap[$resultName].ExitCode | Should -Be 0 -Because "$resultName => $( $ResultMap[$resultName].Text )"
    }

    foreach ($resultName in @('Build', 'BuildCi', 'TestShort', 'TestLong', 'Publish', 'PublishCi', 'Bump', 'BumpCi', 'PreviewBump', 'ReleaseCi')) {
        $ResultMap[$resultName].Text | Should -Match 'What if:'
    }

    foreach ($resultName in @('Publish', 'PublishCi', 'PreviewBump', 'ReleaseCi')) {
        $ResultMap[$resultName].Text | Should -Not -Match 'Unknown argument:'
    }

    $ResultMap.Bump.Text | Should -Match 'Version plan: 0\.0\.1 -> 0\.1\.0 \| Label: Minor \| Commits: 1'
    $ResultMap.BumpCi.Text | Should -Match 'Version plan: 0\.0\.1 -> 0\.1\.0 \| Label: Minor \| Commits: 1'
    $ResultMap.PreviewBump.Text | Should -Match 'Version plan: 0\.0\.1 -> 0\.1\.0-preview \| Label: Minor \| Commits: 1'
    $ResultMap.Bump.Text | Should -Not -Match 'Version bumped to :'
    $ResultMap.PreviewBump.Text | Should -Not -Match 'Version bumped to :'
    ((Get-Content -LiteralPath $ProjectJsonPath -Raw | ConvertFrom-Json).Version) | Should -Be '0.0.1'
    (Test-Path -LiteralPath $BuiltModulePath) | Should -BeFalse
    (Test-Path -LiteralPath $TestResultPath) | Should -BeFalse
}

function Get-TestNovaCliContinuousIntegrationForwardingCaseList {
    [CmdletBinding()]
    param()

    return @(
        @{CommandName = 'build'; ActionCommand = 'Invoke-NovaBuild'; UsesPublishOption = $false; Arguments = @('--continuous-integration')}
        @{CommandName = 'bump'; ActionCommand = 'Update-NovaModuleVersion'; UsesPublishOption = $false; Arguments = @('--continuous-integration')}
        @{CommandName = 'publish'; ActionCommand = 'Publish-NovaModule'; UsesPublishOption = $false; Arguments = @('--repository', 'PSGallery', '--api-key', 'key123', '--continuous-integration')}
        @{CommandName = 'release'; ActionCommand = 'Invoke-NovaRelease'; UsesPublishOption = $true; Arguments = @('--repository', 'PSGallery', '--api-key', 'key123', '--continuous-integration')}
    )
}
