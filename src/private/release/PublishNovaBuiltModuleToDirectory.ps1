function Publish-NovaBuiltModuleToDirectory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ProjectInfo,

        [Parameter(Mandatory)]
        [string]$ModuleDirectoryPath
    )

    $targetPath = Join-Path -Path $ModuleDirectoryPath -ChildPath $ProjectInfo.ProjectName
    if (-not $PSCmdlet.ShouldProcess($targetPath, 'Publish built module to local directory')) {
        return
    }

    if (-not (Test-Path -LiteralPath $ModuleDirectoryPath -PathType Container)) {
        New-Item -Path $ModuleDirectoryPath -ItemType Directory -Force | Out-Null
    }

    $oldModule = $targetPath
    if (Test-Path -LiteralPath $oldModule) {
        Remove-Item -LiteralPath $oldModule -Recurse -Force
    }

    Copy-Item -Path $ProjectInfo.OutputModuleDir -Destination $ModuleDirectoryPath -Recurse -ErrorAction Stop
}

