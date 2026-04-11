function Get-LocalModulePathPattern {
    if ($IsWindows) {
        return '\\Documents\\PowerShell\\Modules'
    }

    return '/\.local/share/powershell/Modules$'
}
