function Set-ScaffoldTestGitEnvironment {
    param([string]$Root)

    $saved = @{}
    foreach ($entry in [Environment]::GetEnvironmentVariables().GetEnumerator()) {
        if ($entry.Key -like 'GIT_*' -or $entry.Key -eq 'EMAIL') {
            $saved[$entry.Key] = $entry.Value
            [Environment]::SetEnvironmentVariable($entry.Key, $null)
        }
    }
    $env:GIT_CONFIG_NOSYSTEM = '1'
    $env:GIT_CONFIG_GLOBAL = Join-Path $Root 'gitconfig'
    $env:GIT_TEMPLATE_DIR = Join-Path $Root 'git-template'
    $null = New-Item -ItemType Directory -Path $env:GIT_TEMPLATE_DIR -Force
    Set-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Value "[user]`nname = Nova Test`nemail = nova@example.invalid`nuseConfigOnly = true`n[commit]`ngpgSign = false"
    return $saved
}

function Restore-ScaffoldTestGitEnvironment {
    param([hashtable]$Saved)

    foreach ($name in @([Environment]::GetEnvironmentVariables().Keys)) {
        if ($name -like 'GIT_*' -or $name -eq 'EMAIL') {
            [Environment]::SetEnvironmentVariable($name, $null)
        }
    }
    foreach ($entry in $Saved.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value)
    }
}

function New-ScaffoldCommitTestContext {
    param([string]$Root, [string]$EnableGit = 'Yes')

    return [pscustomobject]@{
        AnswerSet = @{
            ProjectName = 'DemoModule'
            EnableGit = $EnableGit
            EnablePester = 'No'
            EnableAgenticCopilot = 'No'
        }
        Layout = Get-NovaModuleScaffoldLayout -Path $Root -ProjectName 'DemoModule'
        Example = $false
    }
}

function Invoke-ScaffoldTestGit {
    param([string]$Root, [string[]]$ArgumentList)

    $result = Invoke-NovaGitCommand -ProjectRoot $Root -Arguments $ArgumentList
    if ($result.ExitCode -ne 0) {
        throw "Fixture Git command failed: $($ArgumentList -join ' ')"
    }
    return $result.Output
}

function Write-ScaffoldHeadRequiringHook {
    $hookDirectory = Join-Path $env:GIT_TEMPLATE_DIR 'hooks'
    $null = New-Item -ItemType Directory -Path $hookDirectory -Force
    $hookPath = Join-Path $hookDirectory 'pre-commit'
    Set-Content -LiteralPath $hookPath -Value "#!/bin/sh`ngit rev-parse --verify HEAD >/dev/null 2>&1 || exit 1`nprintf ran > .git/hook-ran`n" -NoNewline
    if (-not $IsWindows) {
        & chmod +x $hookPath
        if ($LASTEXITCODE -ne 0) { throw 'Could not make fixture hook executable.' }
    }
}
