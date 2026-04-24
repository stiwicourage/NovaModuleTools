function Invoke-NovaCliInstallWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $installedPath = Copy-NovaCliLauncher -SourcePath $WorkflowContext.SourcePath -TargetPath $WorkflowContext.TargetPath -Force:$WorkflowContext.Force
    $directoryOnPath = Test-NovaCliDirectoryOnPath -Directory $WorkflowContext.TargetDirectory
    if (-not $directoryOnPath) {
        Write-Warning "Installed nova to $( $WorkflowContext.TargetDirectory ), but that directory is not currently in PATH. Add it to your shell profile before using nova directly from zsh/bash."
    }

    Write-NovaModuleReleaseNotesLink

    return [pscustomobject]@{
        CommandName = 'nova'
        InstalledPath = $installedPath
        DestinationDirectory = $WorkflowContext.TargetDirectory
        DirectoryOnPath = $directoryOnPath
    }
}
