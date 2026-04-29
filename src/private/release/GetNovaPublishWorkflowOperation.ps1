function Get-NovaPublishWorkflowOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$IsLocal,
        [switch]$Release,
        [switch]$SkipTestsRequested
    )

    $validationText = if ($SkipTestsRequested) {
        'build and publish'
    }
    else {
        'build, test, and publish'
    }

    $workflowText = if ($Release) {
        "Run Nova release workflow ($validationText)"
    }
    else {
        "Build, $( $SkipTestsRequested ? 'skip tests, and publish' : 'test, and publish' ) Nova module"
    }

    $destinationText = if ($IsLocal) {
        'local directory'
    }
    else {
        'repository'
    }

    return "$workflowText to $destinationText"
}
