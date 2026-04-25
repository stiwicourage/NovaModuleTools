function Test-NovaPackageUploadExplicitConfirmEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    return $BoundParameters.ContainsKey('Confirm') -and [bool]$BoundParameters.Confirm
}

function Get-NovaPackageUploadWorkflowOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$UploadArtifactList
    )

    $artifactList = @($UploadArtifactList)
    if ($artifactList.Count -eq 1) {
        return "Upload $( $artifactList[0].Type ) package artifact $( $artifactList[0].PackageFileName )"
    }

    return "Upload $( $artifactList.Count ) package artifacts"
}

function Get-NovaPackageUploadWorkflowTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$UploadArtifactList
    )

    $artifactList = @($UploadArtifactList)
    if ($artifactList.Count -eq 1) {
        return $artifactList[0].UploadUrl
    }

    return ($artifactList.UploadUrl -join ', ')
}

function Get-NovaPackageUploadConfirmationPrompt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return [pscustomobject]@{
        Caption = 'Confirm'
        Message = "$( $WorkflowContext.Operation )`nTarget: $( $WorkflowContext.Target )"
        Choice = [ordered]@{
            Y = 'Continue upload'
            A = 'Continue upload for all selected artifacts'
            N = 'Cancel upload'
            L = 'Cancel remaining uploads'
            S = 'Suspend is not supported; cancel upload'
        }
        Default = 'Y'
    }
}

function Write-NovaPackageUploadSuspendNotSupportedWarning {
    [CmdletBinding()]
    param()

    Write-Warning 'Suspend is not supported for Deploy-NovaPackage confirmation. Operation cancelled.'
}

function Confirm-NovaPackageUploadAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][object]$HostUi
    )

    $response = Read-AwesomeChoicePrompt -Ask (Get-NovaPackageUploadConfirmationPrompt -WorkflowContext $WorkflowContext) -HostUi $HostUi
    if ($response -eq 'S') {
        Write-NovaPackageUploadSuspendNotSupportedWarning
    }

    return $response -in @('Y', 'A')
}
