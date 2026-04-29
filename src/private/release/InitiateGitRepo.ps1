function New-InitiateGitRepo {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DirectoryPath
    )

    if (-not (Test-NovaGitCommandAvailable)) {
        Write-Warning 'Git is not installed. Please install Git and initialize repo manually'
        return
    }

    if (Test-Path -LiteralPath (Join-Path $DirectoryPath '.git')) {
        Write-Warning 'A Git repository already exists in this directory.'
        return
    }

    if (-not $PSCmdlet.ShouldProcess($DirectoryPath, "Initiating git on $DirectoryPath")) {
        return
    }

    try {
        $result = Invoke-NovaGitCommand -ProjectRoot $DirectoryPath -Arguments @('init')
    }
    catch {
        Stop-NovaOperation -Message "Failed to initialize Git repo: $( $_.Exception.Message )" -ErrorId 'Nova.Dependency.GitRepositoryInitializationFailed' -Category OpenError -TargetObject $DirectoryPath
    }

    if ($result.ExitCode -ne 0) {
        Stop-NovaOperation -Message (Get-NovaGitInitializationFailureMessage -Result $result) -ErrorId 'Nova.Dependency.GitRepositoryInitializationFailed' -Category OpenError -TargetObject $DirectoryPath
    }

    Write-Verbose 'Git repository initialized successfully'
}

function Get-NovaGitInitializationFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    $details = Get-NovaGitCommandOutputText -Result $Result
    if ( [string]::IsNullOrWhiteSpace($details)) {
        return 'Failed to initialize Git repo.'
    }

    return "Failed to initialize Git repo: $details"
}
