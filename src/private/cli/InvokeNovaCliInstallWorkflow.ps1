function Invoke-NovaCliInstallWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $installedPath = Copy-NovaCliLauncher -SourcePath $WorkflowContext.SourcePath -TargetPath $WorkflowContext.TargetPath -Force:$WorkflowContext.Force
    $directoryOnPath = Test-NovaCliDirectoryOnPath -Directory $WorkflowContext.TargetDirectory
    if (-not $directoryOnPath) {
        Write-Warning "Installed nova to $( $WorkflowContext.TargetDirectory ), but that directory is not currently in PATH. Add it to your shell profile, start a new shell, and then run 'nova --help'."
    }

    $releaseNotesUri = Get-NovaModuleReleaseNotesUri
    $result = [pscustomobject]@{
        CommandName = 'nova'
        InstalledPath = $installedPath
        DestinationDirectory = $WorkflowContext.TargetDirectory
        DirectoryOnPath = $directoryOnPath
        ReleaseNotesUri = $releaseNotesUri
    }

    Write-NovaCliInstallResult -Result $result
    return $result
}

function Write-NovaCliInstallResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    Write-Host "Installed nova launcher: $( $Result.InstalledPath )"

    foreach ($line in (Get-NovaCliInstallNextStepLine -Result $Result)) {
        Write-Host $line
    }
}

function Get-NovaCliInstallNextStepLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    if ($Result.DirectoryOnPath) {
        return @(
            'Next step:'
            'nova --help'
        )
    }

    return @(
        'Next steps:'
        "Add $( $Result.DestinationDirectory ) to your PATH"
        'Start a new shell'
        'nova --help'
    )
}
