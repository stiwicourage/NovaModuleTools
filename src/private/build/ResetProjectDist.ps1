function Reset-ProjectDist {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
    )
    $data = Get-NovaProjectInfo
    try {
        Write-Verbose 'Running dist folder reset'
        if (Test-Path $data.OutputDir) {
            Remove-Item -Path $data.OutputDir -Recurse -Force -ProgressAction SilentlyContinue -ErrorAction Stop
        }
        # Setup Folders
        New-Item -Path $data.OutputDir -ItemType Directory -Force -ErrorAction Stop | Out-Null # Dist folder
        New-Item -Path $data.OutputModuleDir -Type Directory -Force -ErrorAction Stop | Out-Null # Module Folder
    } catch {
        throw "Failed to reset Dist folder: $( $_.Exception.Message )"
    }
}
