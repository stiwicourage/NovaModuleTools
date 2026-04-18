function Install-NovaCli {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$DestinationDirectory,
        [switch]$Force
    )

    if ($IsWindows) {
        throw 'Install-NovaCli currently supports macOS/Linux only. On Windows, use the nova alias inside pwsh after importing NovaModuleTools.'
    }

    $targetDirectory = Get-NovaCliInstallDirectory -DestinationDirectory $DestinationDirectory
    $sourcePath = Get-NovaCliLauncherPath
    $targetPath = Join-Path $targetDirectory 'nova'
    if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
        throw "Target file already exists: $targetPath. Use -Force to overwrite it."
    }

    if (-not $PSCmdlet.ShouldProcess($targetPath, 'Install nova CLI launcher')) {
        return
    }

    $installedPath = Copy-NovaCliLauncher -SourcePath $sourcePath -TargetPath $targetPath -Force:$Force
    $directoryOnPath = Test-NovaCliDirectoryOnPath -Directory $targetDirectory
    if (-not $directoryOnPath) {
        Write-Warning "Installed nova to $targetDirectory, but that directory is not currently in PATH. Add it to your shell profile before using nova directly from zsh/bash."
    }

    return [pscustomobject]@{
        CommandName = 'nova'
        InstalledPath = $installedPath
        DestinationDirectory = $targetDirectory
        DirectoryOnPath = $directoryOnPath
    }
}
