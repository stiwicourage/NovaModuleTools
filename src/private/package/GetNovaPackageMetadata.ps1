function Get-NovaPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata is the established domain term returned by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string]$PackageType,
        [switch]$Latest
    )

    $manifest = $ProjectInfo.Manifest
    $packageSettings = $ProjectInfo.Package
    $configuredPackageTypes = if ($packageSettings -is [System.Collections.IDictionary]) {
        @($packageSettings['Types'])
    }
    else {
        @($packageSettings.Types)
    }
    $defaultPackageType = @($configuredPackageTypes | Where-Object {$_} | Select-Object -First 1)
    $packageType = if ( [string]::IsNullOrWhiteSpace($PackageType)) {
        if ( [string]::IsNullOrWhiteSpace("$( $defaultPackageType )")) {
            'NuGet'
        }
        else {
            ConvertTo-NovaPackageType -Type "$( $defaultPackageType )"
        }
    }
    else {
        ConvertTo-NovaPackageType -Type $PackageType
    }
    $packageId = "$( $ProjectInfo.Package.Id )".Trim()
    $authors = Get-NovaPackageAuthorList -AuthorValue $ProjectInfo.Package.Authors
    $tags = @(@(Get-NovaManifestValue -Manifest $manifest -Name 'Tags') | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    $packageFileName = Get-NovaPackageFileName -ProjectInfo $ProjectInfo -PackageId $packageId -PackageType $packageType -Latest:$Latest
    $outputDirectory = Get-NovaPackageOutputDirectory -ProjectInfo $ProjectInfo
    $cleanOutputDirectory = [bool]$ProjectInfo.Package.OutputDirectory.Clean
    $contentRoot = if ($packageType -eq 'Zip') {
        "$( $ProjectInfo.ProjectName )"
    }
    else {
        "content/$( $ProjectInfo.ProjectName )"
    }

    return [pscustomobject]@{
        Type = $packageType
        Latest = [bool]$Latest
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
        ContentRoot = $contentRoot
    }
}

