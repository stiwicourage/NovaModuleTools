function Resolve-NovaCiProjectInfo {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = (Get-Location).Path,
        [pscustomobject]$ProjectInfo
    )

    if ($null -ne $ProjectInfo) {
        return $ProjectInfo
    }

    return Get-NovaProjectInfo -Path $ProjectRoot
}

function Get-NovaBuiltModuleManifestPathForCi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    return Join-Path $ProjectInfo.OutputModuleDir "$( $ProjectInfo.ProjectName ).psd1"
}

function Import-NovaBuiltModuleForCi {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = (Get-Location).Path,
        [pscustomobject]$ProjectInfo
    )

    $resolvedProjectInfo = Resolve-NovaCiProjectInfo -ProjectRoot $ProjectRoot -ProjectInfo $ProjectInfo
    $moduleManifestPath = Get-NovaBuiltModuleManifestPathForCi -ProjectInfo $resolvedProjectInfo
    if (-not (Test-Path -LiteralPath $moduleManifestPath)) {
        throw "Built module manifest not found: $moduleManifestPath"
    }

    Get-Module -Name $resolvedProjectInfo.ProjectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
    return Import-Module -Name $moduleManifestPath -Force -Global -PassThru -ErrorAction Stop
}

