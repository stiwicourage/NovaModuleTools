function Invoke-NovaBuild {
    [CmdletBinding()]
    param (
    )
    Reset-ProjectDist
    Build-Module

    $data = Get-NovaProjectInfo
    if ($data.FailOnDuplicateFunctionNames) {
        Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $data
    }

    Build-Manifest
    Build-Help
    Copy-ProjectResource
}
