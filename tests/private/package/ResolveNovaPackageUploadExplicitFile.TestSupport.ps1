function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NovaPackageArtifactType {param($PackagePath) if ($PackagePath -match '\.zip$') {'Zip'} else {'NuGet'}}
function Get-NovaPackageUploadFileInfo {param($PackageType, $PackagePath, $PackageFileName)
    return [pscustomobject]@{Type=$PackageType; PackagePath=$PackagePath; PackageFileName=[IO.Path]::GetFileName($PackagePath)}
}
