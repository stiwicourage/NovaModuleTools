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
        throw "Failed to make nova launcher executable: $Path"
    }
}


