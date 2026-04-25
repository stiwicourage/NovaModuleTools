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

function Assert-TestStructuredError {
    [CmdletBinding()]
    param(
        [AllowNull()]$ThrownError,
        [Parameter(Mandatory)][pscustomobject]$ExpectedError
    )

    $ThrownError | Should -Not -BeNullOrEmpty
    $ThrownError.Exception.Message | Should -BeLike $ExpectedError.Message
    $ThrownError.FullyQualifiedErrorId | Should -Be $ExpectedError.ErrorId
    $ThrownError.CategoryInfo.Category | Should -Be $ExpectedError.Category
    if ($ExpectedError.PSObject.Properties.Name -contains 'TargetObject') {
        $ThrownError.TargetObject | Should -Be $ExpectedError.TargetObject
    }
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

function Publish-TestSupportFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$FunctionNameList
    )

    foreach ($functionName in $FunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
}

function Assert-TestModuleIsBuilt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][string]$ModuleDirectory
    )

    if (-not (Test-Path -LiteralPath $ModuleDirectory)) {
        throw "Expected built $ModuleName module at: $ModuleDirectory. Run Invoke-NovaBuild in the repo root first."
    }
}

function Get-TestModuleContextInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CommandPath
    )

    $testsRoot = Split-Path -Parent $CommandPath
    $repoRoot = Split-Path -Parent $testsRoot
    $moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    return [pscustomobject]@{
        ModuleName = $moduleName
        DistModuleDir = Join-Path $repoRoot "dist/$moduleName"
    }
}

function Initialize-TestModuleContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CommandPath,
        [Parameter(Mandatory)][string]$SupportPath,
        [Parameter(Mandatory)][string[]]$FunctionNameList
    )

    $context = Get-TestModuleContextInfo -CommandPath $CommandPath
    Assert-TestModuleIsBuilt -ModuleName $context.ModuleName -ModuleDirectory $context.DistModuleDir
    Remove-Module $context.ModuleName -ErrorAction SilentlyContinue
    Import-Module $context.DistModuleDir -Force
    . $SupportPath
    Publish-TestSupportFunctions -FunctionNameList $FunctionNameList

    return $context
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

function New-UpdateNovaModuleVersionParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$TestCase
    )

    $parameters = @{Path = (Get-Location).Path; WhatIf = $true}
    if ($TestCase.Preview) {
        $parameters.Preview = $true
    }

    return $parameters
}

function Test-GitCommandIsAvailable {
    [CmdletBinding()]
    param()

    return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Initialize-EmptyGitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    & git -C $ProjectRoot init --quiet | Out-Null
    & git -C $ProjectRoot config user.name 'NovaModuleTools Tests' | Out-Null
    & git -C $ProjectRoot config user.email 'tests@example.invalid' | Out-Null
}

function Assert-TestNovaCliConfirmDecisions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        foreach ($testCase in @(
            @{Key = 'Y'; Expected = $true},
            @{Key = 'A'; Expected = $true},
            @{Key = 'N'; Expected = $false},
            @{Key = 'L'; Expected = $false},
            @{Key = 'S'; Expected = $false},
            @{Key = 'y'; Expected = $true},
            @{Key = 'n'; Expected = $false}
        )) {
            $result = Get-NovaCliConfirmDecision -KeyChar ([char]$testCase.Key)
            $result | Should -Be $testCase.Expected
        }

        Get-NovaCliConfirmDecision -KeyChar ([char]'?') | Should -BeNullOrEmpty
    }
}

function Invoke-ReadNovaCliPromptKeyAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        Mock Read-NovaCliConsoleKeyChar {
            if ($TestCase.Throws) {
                throw 'console unavailable'
            }

            return $TestCase.ConsoleKeyChar
        }

        $result = Read-NovaCliPromptKey

        $result | Should -Be $TestCase.Expected
        Assert-MockCalled Read-NovaCliConsoleKeyChar -Times 1
    }
}

function Invoke-GetNovaCliCommandPromptKeyAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        $originalResponse = $env:NOVA_CLI_CONFIRM_RESPONSE
        try {
            $env:NOVA_CLI_CONFIRM_RESPONSE = $TestCase.EnvironmentResponse
            Mock Write-Host {}
            Mock Read-NovaCliPromptKey {[char]'n'}

            $result = Get-NovaCliCommandPromptKey -Message "Continue with 'nova build'?"

            $result | Should -Be $TestCase.Expected
            Assert-MockCalled Read-NovaCliPromptKey -Times $TestCase.PromptReadCount
        }
        finally {
            $env:NOVA_CLI_CONFIRM_RESPONSE = $originalResponse
        }
    }
}

function Invoke-GetNovaCliCommandCancellationInfoAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        $result = Get-NovaCliCommandCancellationInfo -Command 'build' -KeyChar ([char]$TestCase.Key)

        $result.Command | Should -Be 'build'
        $result.Message | Should -Be $TestCase.ExpectedMessage
        $result.ErrorId | Should -Be $TestCase.ExpectedErrorId
    }
}

function Invoke-UpdateNovaModuleVersionDefaultPathAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        Mock Get-Location {[pscustomobject]@{Path = '/tmp/current-project'}}
        Mock Resolve-Path {[pscustomobject]@{Path = '/tmp/current-project'}} -ParameterFilter {$LiteralPath -eq '/tmp/current-project'}
        Mock Get-NovaVersionUpdateWorkflowContext {
            [pscustomobject]@{
                Target = 'project.json'
                Action = 'Update module version using Minor release label'
            }
        }
        Mock Invoke-NovaVersionUpdateWorkflow {
            [pscustomobject]@{NewVersion = '1.1.0'}
        }

        $result = Update-NovaModuleVersion -Confirm:$false

        $result.NewVersion | Should -Be '1.1.0'
        Assert-MockCalled Get-NovaVersionUpdateWorkflowContext -Times 1 -ParameterFilter {
            $ProjectRoot -eq '/tmp/current-project' -and -not $PreviewRelease
        }
    }
}

function Invoke-ConfirmNovaCliCommandActionEnterAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        Mock Get-NovaCliCommandPromptKey {[char]13}
        Mock Write-Host {}
        Mock Stop-NovaOperation {}

        Confirm-NovaCliCommandAction -Command 'build'

        Assert-MockCalled Get-NovaCliCommandPromptKey -Times 1 -ParameterFilter {$Message -eq "Continue with 'nova build'?"}
        Assert-MockCalled Stop-NovaOperation -Times 0
    }
}

function Invoke-ConfirmNovaCliCommandActionRetryAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName
    )

    InModuleScope $ModuleName {
        $script:promptKeyList = @([char]'?', [char]'Y')
        $script:promptKeyIndex = 0
        Mock Get-NovaCliCommandPromptKey {
            $result = $script:promptKeyList[$script:promptKeyIndex]
            $script:promptKeyIndex += 1
            return $result
        }
        Mock Write-Host {}
        Mock Stop-NovaOperation {}

        Confirm-NovaCliCommandAction -Command 'build'

        Assert-MockCalled Get-NovaCliCommandPromptKey -Times 2 -ParameterFilter {$Message -eq "Continue with 'nova build'?"}
        Assert-MockCalled Write-Host -Times 1 -ParameterFilter {$Object -eq ([char]'Y')}
        Assert-MockCalled Stop-NovaOperation -Times 0
    }
}

function Invoke-ConfirmNovaCliCommandActionCancellationAssertion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)]$TestCase
    )

    InModuleScope $ModuleName -Parameters @{TestCase = $TestCase} {
        param($TestCase)

        Mock Get-NovaCliCommandPromptKey {[char]$TestCase.Key}
        Mock Write-Host {}
        Mock Stop-NovaOperation {}

        Confirm-NovaCliCommandAction -Command 'build'

        Assert-MockCalled Write-Host -Times 1 -ParameterFilter {$Object -eq ([char]$TestCase.Key)}
        Assert-MockCalled Stop-NovaOperation -Times 1 -ParameterFilter {
            $Message -eq $TestCase.ExpectedMessage -and
                    $ErrorId -eq $TestCase.ExpectedErrorId -and
                    $Category -eq 'OperationStopped' -and
                    $TargetObject -eq 'build'
        }
    }
}

function Assert-TestNovaCliPublishConfirmationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [Parameter(Mandatory)][string]$PublishManifestPath,
        [Parameter(Mandatory)]$TestCase
    )

    if ($TestCase.ExpectSuccess) {
        $Result.ExitCode | Should -Be 0
        (Test-Path -LiteralPath $PublishManifestPath) | Should -BeTrue
        $Result.Text | Should -Not -Match 'Suspend is not supported in nova CLI mode'
        $Result.Text | Should -Not -Match 'Operation cancelled\.'
        return
    }

    $Result.ExitCode | Should -Not -Be 0
    (Test-Path -LiteralPath $PublishManifestPath) | Should -BeFalse

    if ($TestCase.ExpectSuspendMessage) {
        $Result.Text | Should -Match 'Suspend is not supported in nova CLI mode\. Operation cancelled\.'
        return
    }

    $Result.Text | Should -Match 'Operation cancelled\.'
}

function New-TestPesterConfigStub {
    [CmdletBinding()]
    param(
        [switch]$IncludeOutput
    )

    $config = [ordered]@{
        'Run' = [pscustomobject]@{
            'Path' = $null
            'PassThru' = $false
            'Exit' = $false
            'Throw' = $false
        }
        'Filter' = [pscustomobject]@{
            'Tag' = @()
            'ExcludeTag' = @()
        }
        'TestResult' = [pscustomobject]@{
            'OutputPath' = $null
        }
    }

    if ($IncludeOutput) {
        $config.Output = [pscustomobject]@{
            'Verbosity' = 'Detailed'
            'RenderMode' = 'Auto'
        }
    }

    return [pscustomobject]$config
}

