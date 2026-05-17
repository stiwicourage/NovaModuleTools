function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NovaPackageArtifactPatternInfo {param($ProjectInfo) return [pscustomobject]@{Pattern='X*'; ExplicitPackageType=$null}}
function ConvertTo-NovaPackageType {param($Type) if ($Type -match '(?i)zip') {'Zip'} else {'NuGet'}}
function Get-NovaPackageMetadataList {param($ProjectInfo) return @([pscustomobject]@{Type='NuGet'}, [pscustomobject]@{Type='Zip'})}
