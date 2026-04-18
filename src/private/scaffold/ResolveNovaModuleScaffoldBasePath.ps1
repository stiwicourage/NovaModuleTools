function Resolve-NovaModuleScaffoldBasePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $separator = [string][System.IO.Path]::DirectorySeparatorChar
    $normalizedPath = $Path.Replace('\', $separator).Replace('/', $separator)
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($normalizedPath)

    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
        throw "Not a valid path: $Path"
    }

    return [System.IO.Path]::GetFullPath($resolvedPath)
}
