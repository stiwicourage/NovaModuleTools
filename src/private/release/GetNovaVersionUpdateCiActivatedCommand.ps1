function Get-NovaVersionUpdateCiActivatedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $projectInfo = Get-NovaProjectInfo -Path $ProjectRoot
    $builtManifestPath = Get-NovaBuiltModuleManifestPathForCi -ProjectInfo $projectInfo
    $currentCommand = Get-Command -Name 'Update-NovaModuleVersion' -CommandType Function -ErrorAction Stop

    if ($currentCommand.Module.Path -eq $builtManifestPath) {
        return $null
    }

    $null = Import-NovaBuiltModuleForCi -ProjectInfo $projectInfo
    return Get-Command -Name 'Update-NovaModuleVersion' -CommandType Function -ErrorAction Stop
}

