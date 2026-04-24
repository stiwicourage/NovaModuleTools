function Get-NovaCliInstallWorkflowContext {
    [CmdletBinding()]
    param(
        [string]$DestinationDirectory,
        [switch]$Force
    )

    if ($IsWindows) {
        Stop-NovaOperation -Message 'Install-NovaCli currently supports macOS/Linux only. On Windows, use the nova alias inside pwsh after importing NovaModuleTools.' -ErrorId 'Nova.Environment.UnsupportedCliInstallPlatform' -Category NotImplemented -TargetObject 'Windows'
    }

    $targetDirectory = Get-NovaCliInstallDirectory -DestinationDirectory $DestinationDirectory
    $sourcePath = Get-NovaCliLauncherPath
    $targetPath = Join-Path $targetDirectory 'nova'

    if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
        Stop-NovaOperation -Message "Target file already exists: $targetPath. Use -Force to overwrite it." -ErrorId 'Nova.Workflow.CliInstallTargetExists' -Category ResourceExists -TargetObject $targetPath
    }

    return [pscustomobject]@{
        SourcePath = $sourcePath
        TargetPath = $targetPath
        TargetDirectory = $targetDirectory
        Force = $Force.IsPresent
        Action = 'Install nova CLI launcher'
    }
}
