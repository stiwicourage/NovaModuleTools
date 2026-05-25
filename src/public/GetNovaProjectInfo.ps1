function Get-NovaProjectInfo {
    [CmdletBinding(DefaultParameterSetName = 'ProjectInfo')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'ProjectInfo')]
        [Parameter(Position = 0, ParameterSetName = 'ProjectVersion')]
        [string]$Path = (Get-Location).Path,
        [Parameter(ParameterSetName = 'ProjectVersion')]
        [switch]$Version,
        [Parameter(ParameterSetName = 'InstalledProjectVersion')]
        [switch]$Installed,
        [Parameter(ParameterSetName = 'InstalledNovaVersion')]
        [switch]$InstalledNovaVersion
    )

    if ($Installed) {
        return Get-NovaInstalledProjectVersion
    }

    if ($InstalledNovaVersion) {
        $module = $ExecutionContext.SessionState.Module
        $installedVersion = Get-NovaCliInstalledVersion -Module $module
        return Format-NovaCliVersionString -Name $module.Name -Version $installedVersion
    }

    $workflowContext = Get-NovaProjectInfoContext -Path $Path
    return Get-NovaProjectInfoResult -WorkflowContext $workflowContext -Version:$Version
}
