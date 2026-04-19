function Assert-NovaPackageOutputDirectoryCanBeCleared {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    $resolvedOutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
    if ($resolvedOutputDirectory -eq [System.IO.Path]::GetPathRoot($resolvedOutputDirectory)) {
        throw 'Package.OutputDirectory.Path cannot be a filesystem root when Package.OutputDirectory.Clean is true.'
    }

    foreach ($protectedPath in @($ProjectInfo.ProjectRoot, $ProjectInfo.OutputModuleDir)) {
        if (Test-NovaPathContainsPath -ParentPath $resolvedOutputDirectory -ChildPath $protectedPath) {
            throw "Package.OutputDirectory.Path cannot be cleaned because it would remove required project content: $protectedPath"
        }
    }
}

