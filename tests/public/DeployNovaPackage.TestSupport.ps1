function New-NovaPackageUploadDynamicParameterDictionary {return New-Object 'System.Management.Automation.RuntimeDefinedParameterDictionary'}
function Get-NovaProjectInfo {return [pscustomobject]@{Name='X'}}
function New-NovaPackageUploadOption {param($BoundParameters) return [pscustomobject]@{BoundCount=$BoundParameters.Count}}
function Get-NovaPackageUploadWorkflowContext {param($BoundParameters, $ProjectInfo, $UploadOption)
    return [pscustomobject]@{Target='https://x/repo'; Operation='Upload'; UploadArtifactList=@([pscustomobject]@{Name='a.nupkg'})}
}
function Write-NovaPackageUploadWorkflowContext {param($WorkflowContext) $script:wroteContext = $true}
function Invoke-NovaPackageUploadWorkflow {param($WorkflowContext, $UploadArtifactList)
    $script:invoked = $true
    return @([pscustomobject]@{StatusCode=201})
}
function Write-NovaPackageUploadResultOutput {param($Result) $script:wroteResult = $true}
