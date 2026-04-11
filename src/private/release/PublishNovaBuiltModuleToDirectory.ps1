function Publish-NovaBuiltModuleToDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ProjectInfo,

        [Parameter(Mandatory)]
        [string]$ModuleDirectoryPath
    )

    if (-not (Test-Path -LiteralPath $ModuleDirectoryPath -PathType Container)) {
        New-Item -Path $ModuleDirectoryPath -ItemType Directory -Force | Out-Null
    }

    $oldModule = Join-Path -Path $ModuleDirectoryPath -ChildPath $ProjectInfo.ProjectName
    if (Test-Path -LiteralPath $oldModule) {
        Remove-Item -LiteralPath $oldModule -Recurse -Force
    }

    Copy-Item -Path $ProjectInfo.OutputModuleDir -Destination $ModuleDirectoryPath -Recurse -ErrorAction Stop
}

