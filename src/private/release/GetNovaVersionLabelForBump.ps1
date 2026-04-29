function Get-NovaVersionLabelForBump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [string[]]$CommitMessages = @()
    )

    if ($CommitMessages.Count -gt 0) {
        return Get-VersionLabelFromCommitSet -Messages $CommitMessages
    }

    if (-not (Test-GitRepositoryIsAvailable -ProjectRoot $ProjectRoot)) {
        return 'Patch'
    }

    if (-not (Test-GitRepositoryHasCommittedHead -ProjectRoot $ProjectRoot)) {
        Stop-NovaOperation -Message 'Cannot bump version because the repository has no commits yet. Create an initial commit first.' -ErrorId 'Nova.Workflow.GitRepositoryHasNoCommits' -Category InvalidOperation -TargetObject $ProjectRoot
    }

    if (-not (Test-GitRepositoryHasCommitsSinceLatestTag -ProjectRoot $ProjectRoot)) {
        Stop-NovaOperation -Message 'Cannot bump version because there are no commits since the latest tag.' -ErrorId 'Nova.Workflow.NoCommitsSinceLatestTag' -Category InvalidOperation -TargetObject $ProjectRoot
    }

    return 'Patch'
}

function Test-GitRepositoryIsAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot '.git'))) {
        return $false
    }

    $result = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('rev-parse', '--git-dir')
    return $result.ExitCode -eq 0
}

function Test-GitRepositoryHasCommittedHead {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $result = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('rev-parse', '--verify', 'HEAD')
    return $result.ExitCode -eq 0
}

function Test-GitRepositoryHasCommitsSinceLatestTag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $lastTagResult = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('describe', '--tags', '--abbrev=0')
    $lastTag = Get-NovaGitCommandOutputText -Result $lastTagResult
    if ($lastTagResult.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($lastTag)) {
        return $true
    }

    $commitCountResult = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('rev-list', '--count', "$lastTag..HEAD")
    $commitCount = Get-NovaGitCommandOutputText -Result $commitCountResult
    return $commitCountResult.ExitCode -ne 0 -or $commitCount -ne '0'
}
