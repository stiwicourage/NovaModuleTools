function Invoke-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
    )

    $data = Get-NovaProjectInfo
    if (-not $PSCmdlet.ShouldProcess($data.OutputModuleDir, 'Build Nova module output')) {
        return
    }

    Reset-ProjectDist -Confirm:$false
    Build-Module

    if ($data.FailOnDuplicateFunctionNames) {
        Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $data
    }

    Build-Manifest
    Build-Help
    Copy-ProjectResource
}
