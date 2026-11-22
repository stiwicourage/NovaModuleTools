function Publish-NovaBuiltModuleToDirectory {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ProjectInfo,

        [Parameter(Mandatory)]
        [string]$ModuleDirectoryPath
    )

    if (-not $PSCmdlet.ShouldProcess($ModuleDirectoryPath, 'Copy built module to local module path')) {
        return
    }

    $versionDirectory = Get-NovaLocalPublishVersionDirectory -ProjectInfo $ProjectInfo -ModuleDirectoryPath $ModuleDirectoryPath
    if (Test-Path -LiteralPath $versionDirectory) {
        Remove-Item -LiteralPath $versionDirectory -Recurse -Force -ErrorAction Stop
    }

    New-Item -Path (Split-Path -Parent $versionDirectory) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $ProjectInfo.OutputModuleDir -Destination $versionDirectory -Recurse -ErrorAction Stop
}
