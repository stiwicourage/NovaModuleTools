function Get-NovaPublicCommandIntegrationProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    return [pscustomobject]@{
        ProjectName = 'NovaModuleTools'
        OutputModuleDir = Join-Path $ProjectRoot 'dist/NovaModuleTools'
    }
}

function Import-NovaPublicCommandIntegrationModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    . (Join-Path $ProjectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')

    $projectInfo = Get-NovaPublicCommandIntegrationProjectInfo -ProjectRoot $ProjectRoot
    return Import-NovaBuiltModuleForCi -ProjectRoot $ProjectRoot -ProjectInfo $projectInfo
}

function Invoke-NovaPublicCommandIntegrationInLocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    Push-Location -LiteralPath $Path
    try {
        return & $ScriptBlock
    } finally {
        Pop-Location
    }
}

function Invoke-NovaPublicCommandIntegrationInProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    return Invoke-NovaPublicCommandIntegrationInLocation -Path $ProjectRoot -ScriptBlock $ScriptBlock
}
