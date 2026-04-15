function Get-NovaPublishWorkflowOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$IsLocal,
        [switch]$Release
    )

    $workflowText = if ($Release) {
        'Run Nova release workflow and publish'
    }
    else {
        'Build, test, and publish Nova module'
    }

    $destinationText = if ($IsLocal) {
        'local directory'
    }
    else {
        'repository'
    }

    return "$workflowText to $destinationText"
}

