function Invoke-NovaBuildValidation {
    param($WorkflowContext)

    $script:validated = $true
}

function Invoke-NovaPackageArtifactCreation {
    param($WorkflowContext)

    return @([pscustomobject]@{PackagePath = '/p'})
}

function Write-Message {
    param(
        [string]$Text,
        [string]$color
    )
}
