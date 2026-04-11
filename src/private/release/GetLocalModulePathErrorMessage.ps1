function Get-LocalModulePathErrorMessage {
    param(
        [Parameter(Mandatory)][string]$MatchPattern
    )

    if ($IsWindows) {
        return "No windows module path matching $MatchPattern found"
    }

    return "No macOS/Linux module path matching $MatchPattern found in PSModulePath."
}
