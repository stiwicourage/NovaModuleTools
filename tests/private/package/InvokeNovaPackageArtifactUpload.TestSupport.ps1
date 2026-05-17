function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Invoke-NovaPackageUploadRequest {param($UploadArtifact) return [pscustomobject]@{StatusCode=201}}
function Get-NovaPackageUploadStatusCode {param($Response) return $Response.StatusCode}
