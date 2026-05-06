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

function Get-NovaReleaseBoundValueOrDefault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [Parameter(Mandatory)][string]$Name,
        $DefaultValue = $null
    )

    if ( $BoundParameters.ContainsKey($Name)) {
        return $BoundParameters[$Name]
    }

    return $DefaultValue
}

function Test-NovaReleaseBoundSwitch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [Parameter(Mandatory)][string]$Name
    )

    return $BoundParameters.ContainsKey($Name) -and [bool]$BoundParameters[$Name]
}

function Get-NovaReleaseRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [Parameter(Mandatory)][string]$ParameterSetName
    )

    return [pscustomobject]@{
        ParameterSetName = $ParameterSetName
        PublishOption = Get-NovaReleaseBoundValueOrDefault -BoundParameters $BoundParameters -Name 'PublishOption' -DefaultValue @{}
        LocalRequested = Test-NovaReleaseBoundSwitch -BoundParameters $BoundParameters -Name 'Local'
        Repository = Get-NovaReleaseBoundValueOrDefault -BoundParameters $BoundParameters -Name 'Repository'
        ModuleDirectoryPath = Get-NovaReleaseBoundValueOrDefault -BoundParameters $BoundParameters -Name 'ModuleDirectoryPath'
        ApiKey = Get-NovaReleaseBoundValueOrDefault -BoundParameters $BoundParameters -Name 'ApiKey'
        SkipTestsRequested = Test-NovaReleaseBoundSwitch -BoundParameters $BoundParameters -Name 'SkipTests'
        ContinuousIntegrationRequested = Test-NovaReleaseBoundSwitch -BoundParameters $BoundParameters -Name 'ContinuousIntegration'
        OverrideWarningRequested = Test-NovaReleaseBoundSwitch -BoundParameters $BoundParameters -Name 'OverrideWarning'
    }
}
