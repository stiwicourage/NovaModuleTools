function Get-NovaPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata is the established domain term returned by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $manifest = $ProjectInfo.Manifest
    $packageId = "$( $ProjectInfo.Package.Id )".Trim()
    $authors = Get-NovaPackageAuthorList -AuthorValue $ProjectInfo.Package.Authors
    $tags = @(@(Get-NovaManifestValue -Manifest $manifest -Name 'Tags') | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    $packageFileName = Get-NovaPackageFileName -ProjectInfo $ProjectInfo -PackageId $packageId
    $outputDirectory = Get-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo
    $cleanOutputDirectory = [bool]$ProjectInfo.Package.OutputDirectory.Clean

    return [pscustomobject]@{
        Id = $packageId
        Version = "$( $ProjectInfo.Version )".Trim()
        Authors = $authors
        Description = "$( $ProjectInfo.Package.Description )".Trim()
        Tags = $tags
        ProjectUrl = "$( Get-NovaManifestValue -Manifest $manifest -Name 'ProjectUri' )".Trim()
        ReleaseNotes = "$( Get-NovaManifestValue -Manifest $manifest -Name 'ReleaseNotes' )".Trim()
        LicenseUrl = "$( Get-NovaManifestValue -Manifest $manifest -Name 'LicenseUri' )".Trim()
        PackageFileName = $packageFileName
        OutputDirectory = $outputDirectory
        CleanOutputDirectory = $cleanOutputDirectory
        PackagePath = [System.IO.Path]::Join($outputDirectory, $packageFileName)
        ContentRoot = "content/$( $ProjectInfo.ProjectName )"
    }
}

