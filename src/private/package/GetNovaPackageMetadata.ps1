function Get-NovaPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata is the established domain term returned by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $packageId = "$( $ProjectInfo.Package.Id )".Trim()
    $authors = Get-NovaPackageAuthorList -AuthorValue $ProjectInfo.Package.Authors
    $tags = @($ProjectInfo.Manifest.Tags | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    $packageFileName = Get-NovaPackageFileName -ProjectInfo $ProjectInfo -PackageId $packageId
    $outputDirectory = Get-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo
    $cleanOutputDirectory = [bool]$ProjectInfo.Package.OutputDirectory.Clean

    return [pscustomobject]@{
        Id = $packageId
        Version = "$( $ProjectInfo.Version )".Trim()
        Authors = $authors
        Description = "$( $ProjectInfo.Package.Description )".Trim()
        Tags = $tags
        ProjectUrl = "$( $ProjectInfo.Manifest.ProjectUri )".Trim()
        ReleaseNotes = "$( $ProjectInfo.Manifest.ReleaseNotes )".Trim()
        LicenseUrl = "$( $ProjectInfo.Manifest.LicenseUri )".Trim()
        PackageFileName = $packageFileName
        OutputDirectory = $outputDirectory
        CleanOutputDirectory = $cleanOutputDirectory
        PackagePath = [System.IO.Path]::Join($outputDirectory, $packageFileName)
        ContentRoot = "content/$( $ProjectInfo.ProjectName )"
    }
}

