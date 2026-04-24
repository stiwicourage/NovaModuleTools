function Assert-NovaPackageOutputDirectoryCanBeCleared {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    $resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
    if ($resolvedOutputDirectory -eq [System.IO.Path]::GetPathRoot($resolvedOutputDirectory)) {
        Stop-NovaOperation -Message 'Package.OutputDirectory.Path cannot be a filesystem root when Package.OutputDirectory.Clean is true.' -ErrorId 'Nova.Configuration.PackageOutputDirectoryRootNotAllowed' -Category InvalidData -TargetObject $resolvedOutputDirectory
    }

    foreach ($protectedPath in @($ProjectInfo.ProjectRoot, $ProjectInfo.OutputModuleDir)) {
        if (Test-NovaPathContainsPath -ParentPath $resolvedOutputDirectory -ChildPath $protectedPath) {
            Stop-NovaOperation -Message "Package.OutputDirectory.Path cannot be cleaned because it would remove required project content: $protectedPath" -ErrorId 'Nova.Configuration.PackageOutputDirectoryProtectedPath' -Category InvalidData -TargetObject $protectedPath
        }
    }
}

