function Test-NovaPathContainsPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ParentPath,
        [Parameter(Mandatory)][string]$ChildPath
    )

    $normalizedParentPath = ([System.IO.Path]::GetFullPath($ParentPath)).TrimEnd('/', '\')
    $normalizedChildPath = [System.IO.Path]::GetFullPath($ChildPath)
    if ($normalizedChildPath -eq $normalizedParentPath) {
        return $true
    }

    return $normalizedChildPath.StartsWith("$normalizedParentPath$( [System.IO.Path]::DirectorySeparatorChar )", [System.StringComparison]::OrdinalIgnoreCase)
}

