function Get-NovaReleaseRequestedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters
    )

    if ( $BoundParameters.ContainsKey('Path')) {
        return $BoundParameters.Path
    }

    return (Get-Location).Path
}

function Get-NovaReleaseRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [Parameter(Mandatory)][string]$ParameterSetName
    )

    return [pscustomobject]@{
        ParameterSetName = $ParameterSetName
        PublishOption = if ( $BoundParameters.ContainsKey('PublishOption')) {
            $BoundParameters.PublishOption
        }
        else {
            @{}
        }
        LocalRequested = $BoundParameters.ContainsKey('Local') -and [bool]$BoundParameters.Local
        Repository = if ( $BoundParameters.ContainsKey('Repository')) {
            $BoundParameters.Repository
        }
        else {
            $null
        }
        ModuleDirectoryPath = if ( $BoundParameters.ContainsKey('ModuleDirectoryPath')) {
            $BoundParameters.ModuleDirectoryPath
        }
        else {
            $null
        }
        ApiKey = if ( $BoundParameters.ContainsKey('ApiKey')) {
            $BoundParameters.ApiKey
        }
        else {
            $null
        }
        SkipTestsRequested = $BoundParameters.ContainsKey('SkipTests') -and $BoundParameters.SkipTests
        ContinuousIntegrationRequested = $BoundParameters.ContainsKey('ContinuousIntegration') -and $BoundParameters.ContinuousIntegration
        OverrideWarningRequested = $BoundParameters.ContainsKey('OverrideWarning') -and $BoundParameters.OverrideWarning
    }
}
