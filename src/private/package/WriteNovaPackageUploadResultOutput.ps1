function Write-NovaPackageUploadResultOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Result
    )

    $resolvedResult = @($Result)
    if ($resolvedResult.Count -eq 0) {
        return
    }

    Write-Host (Get-NovaPackageUploadResultSummaryMessage -Result $resolvedResult)

    $nextStepMessage = Get-NovaPackageUploadResultNextStepMessage -Result $resolvedResult
    if ($null -ne $nextStepMessage) {
        Write-Host $nextStepMessage
    }
}

function Get-NovaPackageUploadResultSummaryMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Result
    )

    $artifactCount = @($Result).Count
    if ($artifactCount -eq 1) {
        return 'Uploaded 1 package artifact.'
    }

    return "Uploaded $artifactCount package artifacts."
}

function Get-NovaPackageUploadResultNextStepMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Result
    )

    $resolvedResult = @($Result)
    if ($resolvedResult.Count -eq 0) {
        return $null
    }

    if ($resolvedResult.Count -eq 1 -and -not [string]::IsNullOrWhiteSpace($resolvedResult[0].UploadUrl)) {
        return "Next step: verify the uploaded artifact at $( $resolvedResult[0].UploadUrl )."
    }

    return 'Next step: verify the uploaded artifacts at the target repository.'
}
