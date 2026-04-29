function Get-NovaVersionUpdateCiActivatedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $projectInfo = Get-NovaProjectInfo -Path $ProjectRoot
    $builtModulePath = Join-Path $projectInfo.OutputModuleDir "$( $projectInfo.ProjectName ).psm1"
    $currentCommand = Get-Command -Name 'Update-NovaModuleVersion' -CommandType Function -ErrorAction Stop

    if ($currentCommand.ScriptBlock.Module.Path -eq $builtModulePath) {
        return $null
    }

    $importedModule = Import-NovaBuiltModuleForCi -ProjectInfo $projectInfo
    return $importedModule.ExportedCommands['Update-NovaModuleVersion']
}
