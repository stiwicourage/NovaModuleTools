function ConvertTo-NovaPackageType {param($Type) if ($Type -match '(?i)zip') {'Zip'} else {'NuGet'}}
function Get-NovaPackageAuthorList {param($AuthorValue) return @($AuthorValue)}
function Get-NovaManifestValue {param($Manifest, $Name) return $Manifest.$Name}
function Get-NovaPackageFileName {param($ProjectInfo, $PackageId, $PackageType, [switch]$Latest)
    $base = "$PackageId.$($ProjectInfo.Version)"
    if ($Latest) {$base = "$PackageId.latest"}
    return "$base$( if ($PackageType -eq 'Zip') {'.zip'} else {'.nupkg'} )"
}
function Get-NovaPackageOutputDirectory {param($ProjectInfo) return '/output'}
