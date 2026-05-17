function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Resolve-NovaPackageUploadTypeList {param($ProjectInfo, $PackageType) return @('NuGet')}
function Get-NovaPackageOutputDirectory {param($ProjectInfo) return $script:outputDirectory}
function Resolve-NovaPackageUploadOutputFileSet {param($OutputDirectory, $ProjectInfo, $PackageType)
    return @([pscustomobject]@{Type=$PackageType; PackagePath=Join-Path $OutputDirectory 'x.nupkg'})
}
