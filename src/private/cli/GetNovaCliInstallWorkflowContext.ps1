function Get-NovaCliInstallWorkflowContext {
    [CmdletBinding()]
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

    return [pscustomobject]@{
        SourcePath = $sourcePath
        TargetPath = $targetPath
        TargetDirectory = $targetDirectory
        Force = $Force.IsPresent
        Action = 'Install nova CLI launcher'
    }
}
