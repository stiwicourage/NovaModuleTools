function Import-NovaBuiltModuleForCi {
    param($ProjectInfo)

    $script:ciImportCalls += 1
}

function Invoke-NovaBuildValidation {
    param($WorkflowContext)

    $script:validationCalls += 1
}

function Write-Message {
    param(
        [string]$Text,
        [string]$color
    )
}

function Write-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete,
        [switch]$Completed
    )
}
