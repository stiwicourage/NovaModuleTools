function Copy-NovaPublishOption {
    [CmdletBinding()]
    param(
        [hashtable]$PublishOption = @{}
    )

    $copiedPublishOption = @{}
    foreach ($optionName in $PublishOption.Keys) {
        $copiedPublishOption[$optionName] = $PublishOption[$optionName]
    }

    return $copiedPublishOption
}

function Get-NovaReleasePublishOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ReleaseParameters
    )

    # TODO: Remove the PublishOption parameter-set branch after 2026-07-01.
    $releasePublishOption = if ($ReleaseParameters.ParameterSetName -eq 'PublishOption') {
        Copy-NovaPublishOption -PublishOption $ReleaseParameters.PublishOption
    }
    else {
        @{
            Local = $ReleaseParameters.LocalRequested
            Repository = $ReleaseParameters.Repository
            ModuleDirectoryPath = $ReleaseParameters.ModuleDirectoryPath
            ApiKey = $ReleaseParameters.ApiKey
        }
    }

    $releasePublishOption.SkipTests = $ReleaseParameters.SkipTestsRequested
    $releasePublishOption.ContinuousIntegration = $ReleaseParameters.ContinuousIntegrationRequested
    $releasePublishOption.OverrideWarning = $ReleaseParameters.OverrideWarningRequested
    return $releasePublishOption
}

