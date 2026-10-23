function Complete-ScaffoldGitRepository {
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$WorkflowContext)

    $projectRoot = $WorkflowContext.Layout.Project
    if (-not (Test-ScaffoldGitInitializationAllowed -ProjectRoot $projectRoot)) {
        return
    }
    $createdFileList = @(Get-ScaffoldCommitFileList -WorkflowContext $WorkflowContext)
    Write-Message 'Initializing Git repository'
    if (-not (New-InitiateGitRepo -DirectoryPath $projectRoot -PassThru -Confirm:$false)) {
        return
    }
    Write-ScaffoldInitialCommit -ProjectRoot $projectRoot -CreatedFileList $createdFileList
}

function Test-ScaffoldGitInitializationAllowed {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    if (-not (Test-NovaGitCommandAvailable)) {
        Write-Warning 'Git is not installed. Scaffold files were created; install Git and initialize the repository manually.'
        return $false
    }
    $repository = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('rev-parse', '--git-dir')
    if ((Test-ScaffoldGitDirectory -ProjectRoot $ProjectRoot) -or $repository.ExitCode -eq 0) {
        Write-Warning 'An existing Git repository was detected. No repository configuration, staging, or automatic initial commit was performed.'
        return $false
    }
    return $true
}

function Test-ScaffoldGitDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $directory = [System.IO.DirectoryInfo]::new($ProjectRoot)
    while ($null -ne $directory) {
        if (Test-Path -LiteralPath (Join-Path $directory.FullName '.git')) {
            return $true
        }
        $directory = $directory.Parent
    }
    return $false
}

function Get-ScaffoldCommitFileList {
    [CmdletBinding()]
    param([Parameter(Mandatory)][pscustomobject]$WorkflowContext)

    $relativePaths = @('.gitignore', 'project.json', '.vscode/settings.json')
    if ($WorkflowContext.Example) {
        $templateRoot = Split-Path -Parent (Get-NovaModuleProjectTemplatePath -Example)
        $relativePaths += @(Get-ScaffoldTemplateFileList -TemplateRoot $templateRoot)
    }
    if ($WorkflowContext.AnswerSet.EnableAgenticCopilot -eq 'Yes') {
        $relativePaths += @(Get-ScaffoldTemplateFileList -TemplateRoot (Get-NovaModuleAgenticCopilotTemplateRoot))
    }
    return $relativePaths | Sort-Object -Unique | Where-Object {
        Test-Path -LiteralPath (Join-Path $WorkflowContext.Layout.Project $_) -PathType Leaf
    }
}

function Get-ScaffoldTemplateFileList {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$TemplateRoot)

    Get-ChildItem -LiteralPath $TemplateRoot -Recurse -File -Force | ForEach-Object {
        $relativePath = [System.IO.Path]::GetRelativePath($TemplateRoot, $_.FullName).Replace('\', '/')
        if ($relativePath -notlike '.git/*') {
            $relativePath
        }
    }
}

function Test-ScaffoldGitIdentity {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    foreach ($identity in @('GIT_AUTHOR_IDENT', 'GIT_COMMITTER_IDENT')) {
        $result = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('var', $identity)
        if ($result.ExitCode -ne 0) {
            Write-Warning 'Initial commit skipped: Git identity is unavailable. Configure Git user.name and user.email, then review and commit the generated files manually. Scaffold files and Git hooks were preserved.'
            return $false
        }
    }
    return $true
}

function Invoke-ScaffoldGitCheckedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string[]]$ArgumentList
    )

    $result = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments $ArgumentList
    if ($result.ExitCode -ne 0) {
        Stop-NovaOperation -Message "Git initial commit step failed ($($ArgumentList[0]), exit $($result.ExitCode)). Scaffold files and hooks were preserved. Inspect the repository and complete the initial commit manually." -ErrorId 'Nova.Dependency.GitInitialCommitFailed' -Category InvalidOperation -TargetObject $ProjectRoot
    }
    return $result
}

function Get-ScaffoldCommitEligibleFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$CreatedFileList
    )

    if ($CreatedFileList.Count -eq 0) { return }
    $arguments = @('--literal-pathspecs', 'ls-files', '--others', '--exclude-standard', '-z', '--') + $CreatedFileList
    $result = Invoke-ScaffoldGitCheckedCommand -ProjectRoot $ProjectRoot -ArgumentList $arguments
    return (($result.Output -join "`n") -split "`0") | Where-Object { $_.Length -gt 0 }
}

function Write-ScaffoldInitialCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$CreatedFileList
    )

    if (-not (Test-ScaffoldGitIdentity -ProjectRoot $ProjectRoot)) { return }
    if (-not (Test-ScaffoldGitIndexEmpty -ProjectRoot $ProjectRoot)) { return }
    $eligibleFiles = @(Get-ScaffoldCommitEligibleFile -ProjectRoot $ProjectRoot -CreatedFileList $CreatedFileList)
    if ($eligibleFiles.Count -eq 0) {
        Write-Warning 'No generated files are eligible for the initial commit. Review Git ignore rules and commit manually.'
        return
    }
    Invoke-ScaffoldInitialCommitCommand -ProjectRoot $ProjectRoot -EligibleFileList $eligibleFiles
}

function Test-ScaffoldGitIndexEmpty {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $index = Invoke-ScaffoldGitCheckedCommand -ProjectRoot $ProjectRoot -ArgumentList @('ls-files', '--cached', '-z')
    if (($index.Output -join '').Length -gt 0) {
        Write-Warning 'Initial commit skipped: the Git index already contains files. Review and commit the generated files manually.'
        return $false
    }
    return $true
}

function Invoke-ScaffoldInitialCommitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string[]]$EligibleFileList
    )

    $null = Invoke-ScaffoldGitCheckedCommand -ProjectRoot $ProjectRoot -ArgumentList (@('--literal-pathspecs', 'add', '--') + $EligibleFileList)
    $null = Invoke-ScaffoldGitCheckedCommand -ProjectRoot $ProjectRoot -ArgumentList @('commit', '--no-verify', '-m', 'chore: Initial commit')
    $null = Invoke-ScaffoldGitCheckedCommand -ProjectRoot $ProjectRoot -ArgumentList @('rev-parse', '--verify', 'HEAD')
    Write-Message 'Created initial Git commit: chore: Initial commit' -color Green
}
