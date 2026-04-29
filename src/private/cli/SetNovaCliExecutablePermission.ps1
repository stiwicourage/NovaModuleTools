function Set-NovaCliExecutablePermission {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if ($IsWindows) {
        return
    }

    if (-not $PSCmdlet.ShouldProcess($Path, 'Make nova launcher executable')) {
        return
    }

    & chmod '+x' $Path
    if ($LASTEXITCODE -ne 0) {
        Stop-NovaOperation -Message "Failed to make nova launcher executable: $Path" -ErrorId 'Nova.Dependency.CliLauncherPermissionUpdateFailed' -Category InvalidOperation -TargetObject $Path
    }
}
