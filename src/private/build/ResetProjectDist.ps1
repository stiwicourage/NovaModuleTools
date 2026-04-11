function Reset-ProjectDist {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
    )
    $ErrorActionPreference = 'Stop'
    $data = Get-NovaProjectInfo
    try {
        Write-Verbose 'Running dist folder reset'
        if (Test-Path $data.OutputDir) {
            Remove-Item -Path $data.OutputDir -Recurse -Force -ProgressAction SilentlyContinue
        }
        # Setup Folders
        New-Item -Path $data.OutputDir -ItemType Directory -Force | Out-Null # Dist folder
        New-Item -Path $data.OutputModuleDir -Type Directory -Force | Out-Null # Module Folder
    } catch {
        Write-Error 'Failed to reset Dist folder'
    }
}
