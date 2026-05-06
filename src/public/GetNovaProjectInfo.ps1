function Get-NovaProjectInfo {
    [CmdletBinding(DefaultParameterSetName = 'ProjectInfo')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'ProjectInfo')]
        [Parameter(Position = 0, ParameterSetName = 'ProjectVersion')]
        [string]$Path = (Get-Location).Path,
        [Parameter(ParameterSetName = 'ProjectVersion')]
        [switch]$Version,
        [Parameter(ParameterSetName = 'InstalledVersion')]
        [switch]$Installed
    )

    if ($Installed) {
        $module = $ExecutionContext.SessionState.Module
        $installedVersion = Get-NovaCliInstalledVersion -Module $module
        return Format-NovaCliVersionString -Name $module.Name -Version $installedVersion
    }

    $workflowContext = Get-NovaProjectInfoContext -Path $Path
    return Get-NovaProjectInfoResult -WorkflowContext $workflowContext -Version:$Version
}
