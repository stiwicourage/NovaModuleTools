function Get-NovaCliBaseInvocationData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$CommonParameters,
        [Parameter(Mandatory)][hashtable]$MutatingCommonParameters,
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][bool]$WhatIfEnabled
    )

    return [pscustomobject]@{
        CommonParameters = $CommonParameters
        MutatingCommonParameters = $MutatingCommonParameters
        ModuleName = $ModuleName
        WhatIfEnabled = $WhatIfEnabled
    }
}

function Get-NovaCliHelpInvocationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$HelpRequest,
        [Parameter(Mandatory)][pscustomobject]$BaseInvocationData
    )

    return [pscustomobject]@{
        Command = $HelpRequest.Command
        Arguments = @()
        CommonParameters = $BaseInvocationData.CommonParameters
        MutatingCommonParameters = $BaseInvocationData.MutatingCommonParameters
        IsHelpRequest = $true
        HelpRequest = $HelpRequest
        ModuleName = $BaseInvocationData.ModuleName
        WhatIfEnabled = $BaseInvocationData.WhatIfEnabled
        CliConfirmEnabled = $false
    }
}

function Get-NovaCliConfirmState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$MutatingCommonParameters
    )

    if (-not $MutatingCommonParameters.ContainsKey('Confirm')) {
        return $false
    }

    $cliConfirmEnabled = [bool]$MutatingCommonParameters.Confirm
    $MutatingCommonParameters.Remove('Confirm')
    return $cliConfirmEnabled
}

function Get-NovaCliRoutedInvocationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$RoutingState,
        [Parameter(Mandatory)][pscustomobject]$BaseInvocationData,
        [Parameter(Mandatory)][bool]$CliConfirmEnabled
    )

    return [pscustomobject]@{
        Command = $RoutingState.Command
        Arguments = $RoutingState.Arguments
        CommonParameters = $BaseInvocationData.CommonParameters
        MutatingCommonParameters = $BaseInvocationData.MutatingCommonParameters
        IsHelpRequest = $false
        HelpRequest = $null
        ModuleName = $BaseInvocationData.ModuleName
        WhatIfEnabled = $BaseInvocationData.WhatIfEnabled
        CliConfirmEnabled = $CliConfirmEnabled
    }
}

function Get-NovaCliInvocationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationRequest,
        [switch]$WhatIfEnabled
    )

    $commonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $InvocationRequest.BoundParameters
    $mutatingCommonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $InvocationRequest.BoundParameters -IncludeShouldProcess
    $normalizedArguments = ConvertTo-NovaCliArgumentArray -BoundParameters $InvocationRequest.BoundParameters -Arguments $InvocationRequest.Arguments

    Assert-NovaCliArgumentSyntax -Arguments (@($InvocationRequest.Command) + $normalizedArguments)
    $helpRequest = Get-NovaCliHelpRequest -Command $InvocationRequest.Command -Arguments $normalizedArguments
    $moduleName = $ExecutionContext.SessionState.Module.Name
    $helpBaseInvocationData = Get-NovaCliBaseInvocationData -CommonParameters $commonParameters -MutatingCommonParameters $mutatingCommonParameters -ModuleName $moduleName -WhatIfEnabled:($WhatIfEnabled.IsPresent -or $mutatingCommonParameters.ContainsKey('WhatIf'))

    if ($null -ne $helpRequest) {
        return Get-NovaCliHelpInvocationContext -HelpRequest $helpRequest -BaseInvocationData $helpBaseInvocationData
    }

    $routingState = Get-NovaCliArgumentRoutingState -Command $InvocationRequest.Command -Arguments $normalizedArguments
    $cliConfirmEnabled = Get-NovaCliConfirmState -MutatingCommonParameters $mutatingCommonParameters

    if ( $routingState.ForwardedParameters.ContainsKey('Verbose')) {
        $commonParameters.Verbose = $true
    }

    $mutatingCommonParameters = Merge-NovaCliParameterSet -BaseParameters $mutatingCommonParameters -AdditionalParameters $routingState.ForwardedParameters
    $cliConfirmEnabled = $cliConfirmEnabled -or $routingState.CliConfirmEnabled
    $routedBaseInvocationData = Get-NovaCliBaseInvocationData -CommonParameters $commonParameters -MutatingCommonParameters $mutatingCommonParameters -ModuleName $moduleName -WhatIfEnabled:($WhatIfEnabled.IsPresent -or $routingState.WhatIfEnabled -or $mutatingCommonParameters.ContainsKey('WhatIf'))

    return Get-NovaCliRoutedInvocationContext -RoutingState $routingState -BaseInvocationData $routedBaseInvocationData -CliConfirmEnabled:$cliConfirmEnabled
}
