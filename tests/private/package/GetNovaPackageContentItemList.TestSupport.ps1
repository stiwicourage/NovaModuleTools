function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NormalizedRelativePath {param($Root, $FullName) return [System.IO.Path]::GetFileName($FullName)}
