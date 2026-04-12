function Copy-NovaCliLauncher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$TargetPath,
        [switch]$Force
    )

    $targetDirectory = Split-Path -Parent $TargetPath
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force:$Force -ErrorAction Stop
    Set-NovaCliExecutablePermission -Path $TargetPath
    return $TargetPath
}

