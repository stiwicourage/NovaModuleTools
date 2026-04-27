function Get-NovaModuleVersionWriteResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectFile,
        [Parameter(Mandatory)][string]$PreviousVersion,
        [Parameter(Mandatory)][string]$NewVersion,
        [switch]$Applied
    )

    return [pscustomobject]@{
        ProjectFile = $ProjectFile
        Target = [System.IO.Path]::GetFileName($ProjectFile)
        PreviousVersion = $PreviousVersion
        NewVersion = $NewVersion
        Applied = [bool]$Applied
    }
}

function Set-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Label = 'Patch',
        [switch]$PreviewRelease,
        [switch]$StableRelease,
        [pscustomobject]$ProjectInfo
    )
    Write-Verbose 'Running Version Update'

    $versionUpdatePlan = Get-NovaVersionUpdatePlan -ProjectInfo $ProjectInfo -Label $Label -PreviewRelease:$PreviewRelease -StableRelease:$StableRelease
    $jsonContent = Read-ProjectJsonData -ProjectJsonPath $versionUpdatePlan.ProjectFile
    $previousVersion = [string]$jsonContent.Version
    $newVersion = $versionUpdatePlan.NewVersion.ToString()
    $target = [System.IO.Path]::GetFileName($versionUpdatePlan.ProjectFile)
    $action = "Set module version to $newVersion"

    if (-not $PSCmdlet.ShouldProcess($target, $action)) {
        return Get-NovaModuleVersionWriteResult -ProjectFile $versionUpdatePlan.ProjectFile -PreviousVersion $previousVersion -NewVersion $newVersion
    }

    $jsonContent.Version = $newVersion
    Write-ProjectJsonData -ProjectJsonPath $versionUpdatePlan.ProjectFile -Data $jsonContent
    return Get-NovaModuleVersionWriteResult -ProjectFile $versionUpdatePlan.ProjectFile -PreviousVersion $previousVersion -NewVersion $newVersion -Applied
}
