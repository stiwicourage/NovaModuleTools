function Get-TestRegexMatchGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Pattern
    )

    if ($Content -match $Pattern) {
        return $matches[1].Trim()
    }

    return $null
}

function ConvertTo-TestNormalizedText {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text
    )

    if ( [string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    return ($Text -replace '\s+', ' ').Trim()
}

function Get-TestModuleDisplayVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Module
    )

    $versionText = $Module.Version.ToString()
    $prereleaseLabel = $null
    $psData = $Module.PrivateData.PSData

    if ($psData -is [hashtable]) {
        $prereleaseLabel = $psData['Prerelease']
    }
    elseif ($null -ne $psData -and $psData.PSObject.Properties.Name -contains 'Prerelease') {
        $prereleaseLabel = $psData.Prerelease
    }

    if ( [string]::IsNullOrWhiteSpace($prereleaseLabel)) {
        return $versionText
    }

    return "$versionText-$prereleaseLabel"
}

function Get-TestHelpLocaleFromMarkdownFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo[]]$Files
    )

    $locales = @(
    $Files |
            ForEach-Object {
                $content = Get-Content -LiteralPath $_.FullName -Raw
                $pattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape('Locale')
                Get-TestRegexMatchGroup -Content $content -Pattern $pattern
            } |
            Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |
            Select-Object -Unique
    )

    if ($locales.Count -gt 1) {
        throw "Multiple help locales found in docs metadata: $( $locales -join ', ' )"
    }

    if ($locales.Count -eq 1) {
        return $locales[0]
    }

    return 'en-US'
}

function Get-CommandHelpActivationTestCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$File
    )

    $content = Get-Content -LiteralPath $File.FullName -Raw
    $documentTypePattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape('document type')
    $documentType = Get-TestRegexMatchGroup -Content $content -Pattern $documentTypePattern
    if ($documentType -ne 'cmdlet') {
        return $null
    }

    $titlePattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape('title')
    $helpTarget = Get-TestRegexMatchGroup -Content $content -Pattern $titlePattern
    if ( [string]::IsNullOrWhiteSpace($helpTarget)) {
        $helpTarget = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    }

    $synopsisPattern = '(?ms)^##\s+{0}\s*$\r?\n+(.*?)(?=^##\s+|\z)' -f [regex]::Escape('SYNOPSIS')

    return [pscustomobject]@{
        FileName = $File.Name
        HelpTarget = $helpTarget
        ExpectedSynopsis = ConvertTo-TestNormalizedText -Text (Get-TestRegexMatchGroup -Content $content -Pattern $synopsisPattern)
    }
}

function Get-CommandHelpActivationTestCases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DocsDir
    )

    $helpMarkdownFiles = Get-ChildItem -LiteralPath $DocsDir -Filter '*.md' -Recurse
    return @(
    $helpMarkdownFiles |
            ForEach-Object {Get-CommandHelpActivationTestCase -File $_} |
            Where-Object {$_}
    )
}

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
        [Parameter(Mandatory)][string[]]$Arguments
    )

    Push-Location $WorkingDirectory
    try {
        $output = & $InstalledPath @Arguments 2>&1
        return [pscustomobject]@{Output = @($output); Text = @($output) -join [Environment]::NewLine; ExitCode = $LASTEXITCODE}
    }
    finally {
        Pop-Location
    }
}

function New-TestPesterConfigStub {
    [CmdletBinding()]
    param(
        [switch]$IncludeOutput
    )

    $config = [ordered]@{
        Run = [pscustomobject]@{
            Path = $null
            PassThru = $false
            Exit = $false
            Throw = $false
        }
        Filter = [pscustomobject]@{
            Tag = @()
            ExcludeTag = @()
        }
        TestResult = [pscustomobject]@{
            OutputPath = $null
        }
    }

    if ($IncludeOutput) {
        $config.Output = [pscustomobject]@{
            Verbosity = 'Detailed'
            RenderMode = 'Auto'
        }
    }

    return [pscustomobject]$config
}

