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
    $jsonContent = Get-Content -LiteralPath $versionUpdatePlan.ProjectFile -Raw | ConvertFrom-Json
    $newVersion = $versionUpdatePlan.NewVersion.ToString()
    $target = [System.IO.Path]::GetFileName($versionUpdatePlan.ProjectFile)
    $action = "Set module version to $newVersion"

    if ( $PSCmdlet.ShouldProcess($target, $action)) {
        # Update the version in the JSON object
        $jsonContent.Version = $newVersion
        Write-Host "Version bumped to : $newVersion"

        # Convert the JSON object back to JSON format
        $newJsonContent = $jsonContent | ConvertTo-Json -Depth 20

        # Write the updated JSON back to the file
        $newJsonContent | Set-Content -LiteralPath $versionUpdatePlan.ProjectFile
    }
}
