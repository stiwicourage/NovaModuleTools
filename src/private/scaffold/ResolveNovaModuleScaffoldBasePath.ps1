function Resolve-NovaModuleScaffoldBasePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $separator = [string][System.IO.Path]::DirectorySeparatorChar
    $normalizedPath = $Path.Replace('\', $separator).Replace('/', $separator)
    $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($normalizedPath)

    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
        Stop-NovaOperation -Message "Not a valid path: $Path" -ErrorId 'Nova.Environment.ScaffoldBasePathNotFound' -Category ObjectNotFound -TargetObject $Path
    }

    return [System.IO.Path]::GetFullPath($resolvedPath)
}
