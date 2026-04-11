function Set-NovaModuleVersion {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Label = 'Patch',
        [switch]$PreviewRelease,
        [switch]$StableRelease
    )
    Write-Verbose 'Running Version Update'

    $data = Get-NovaProjectInfo
    $jsonContent = Get-Content -Path $data.ProjectJSON | ConvertFrom-Json

    [semver]$CurrentVersion = $jsonContent.Version
    $versionPart = Get-NovaVersionPartForLabel -CurrentVersion $CurrentVersion -Label $Label
    $releaseType = Get-NovaVersionPreReleaseLabel -CurrentVersion $CurrentVersion -PreviewRelease:$PreviewRelease -StableRelease:$StableRelease
    $newVersion = [semver]::new($versionPart.Major, $versionPart.Minor, $versionPart.Patch, $releaseType, $null)

    $target = $data.ProjectJSON
    $action = "Set module version to $newVersion"

    if ( $PSCmdlet.ShouldProcess($target, $action)) {
        # Update the version in the JSON object
        $jsonContent.Version = $newVersion.ToString()
        Write-Host "Version bumped to : $newVersion"

        # Convert the JSON object back to JSON format
        $newJsonContent = $jsonContent | ConvertTo-Json

        # Write the updated JSON back to the file
        $newJsonContent | Set-Content -Path $data.ProjectJSON
    }
}
