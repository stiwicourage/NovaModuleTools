function Set-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Label = 'Patch',
        [switch]$PreviewRelease,
        [switch]$StableRelease
    )
    Write-Verbose 'Running Version Update'

    $versionUpdatePlan = Get-NovaVersionUpdatePlan -Label $Label -PreviewRelease:$PreviewRelease -StableRelease:$StableRelease
    $jsonContent = Read-ProjectJsonData -ProjectJsonPath $versionUpdatePlan.ProjectFile
    $newVersion = $versionUpdatePlan.NewVersion.ToString()
    $target = [System.IO.Path]::GetFileName($versionUpdatePlan.ProjectFile)
    $action = "Set module version to $newVersion"

    if ( $PSCmdlet.ShouldProcess($target, $action)) {
        $jsonContent.Version = $newVersion
        Write-Host "Version bumped to : $newVersion"
        Write-ProjectJsonData -ProjectJsonPath $versionUpdatePlan.ProjectFile -Data $jsonContent
    }
}
