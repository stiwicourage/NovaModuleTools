function Get-NovaProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,
        [switch]$Version
    )
    $workflowContext = Get-NovaProjectInfoContext -Path $Path
    return Get-NovaProjectInfoResult -WorkflowContext $workflowContext -Version:$Version
}
