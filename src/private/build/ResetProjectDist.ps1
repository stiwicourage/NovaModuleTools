function Reset-ProjectDist {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [pscustomobject]$ProjectInfo
    )
    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo
    try {
        Write-Verbose 'Running dist folder reset'
        if (Test-Path $data.OutputDir) {
            Remove-Item -Path $data.OutputDir -Recurse -Force -ProgressAction SilentlyContinue -ErrorAction Stop
        }
        # Setup Folders
        New-Item -Path $data.OutputDir -ItemType Directory -Force -ErrorAction Stop | Out-Null # Dist folder
        New-Item -Path $data.OutputModuleDir -Type Directory -Force -ErrorAction Stop | Out-Null # Module Folder
    } catch {
        Stop-NovaOperation -Message "Failed to reset Dist folder: $( $_.Exception.Message )" -ErrorId 'Nova.Dependency.DistResetFailed' -Category OpenError -TargetObject $data.OutputDir
    }
}
