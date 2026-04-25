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

