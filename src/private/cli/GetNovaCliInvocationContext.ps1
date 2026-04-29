function Get-NovaCliResolvedInvocationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [AllowEmptyCollection()][string[]]$Arguments = @(),
        [Parameter(Mandatory)][hashtable]$CommonParameters,
        [Parameter(Mandatory)][hashtable]$MutatingCommonParameters,
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][bool]$WhatIfEnabled,
        [Parameter(Mandatory)][bool]$CliConfirmEnabled,
        [AllowNull()][pscustomobject]$HelpRequest = $null
    )

    return [pscustomobject]@{
        Command = $Command
        Arguments = @($Arguments)
        CommonParameters = $CommonParameters
        MutatingCommonParameters = $MutatingCommonParameters
        IsHelpRequest = $null -ne $HelpRequest
        HelpRequest = $HelpRequest
        ModuleName = $ModuleName
        WhatIfEnabled = $WhatIfEnabled
        CliConfirmEnabled = $CliConfirmEnabled
    }
}

function Get-NovaCliInvocationWhatIfState {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled,
        [Parameter(Mandatory)][hashtable]$MutatingCommonParameters,
        [switch]$RoutingWhatIfEnabled
    )

    return $WhatIfEnabled.IsPresent -or $RoutingWhatIfEnabled.IsPresent -or $MutatingCommonParameters.ContainsKey('WhatIf')
}

function Get-NovaCliInvocationConfirmState {
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
    $whatIfState = Get-NovaCliInvocationWhatIfState -WhatIfEnabled:$WhatIfEnabled -MutatingCommonParameters $mutatingCommonParameters

    if ($null -ne $helpRequest) {
        return Get-NovaCliResolvedInvocationContext -Command $helpRequest.Command -Arguments @() -CommonParameters $commonParameters -MutatingCommonParameters $mutatingCommonParameters -ModuleName $moduleName -WhatIfEnabled:$whatIfState -CliConfirmEnabled:$false -HelpRequest $helpRequest
    }

    $routingState = Get-NovaCliArgumentRoutingState -Command $InvocationRequest.Command -Arguments $normalizedArguments
    $cliConfirmEnabled = Get-NovaCliInvocationConfirmState -MutatingCommonParameters $mutatingCommonParameters

    if ( $routingState.ForwardedParameters.ContainsKey('Verbose')) {
        $commonParameters.Verbose = $true
    }

    $mutatingCommonParameters = Merge-NovaCliParameterSet -BaseParameters $mutatingCommonParameters -AdditionalParameters $routingState.ForwardedParameters
    $cliConfirmEnabled = $cliConfirmEnabled -or $routingState.CliConfirmEnabled
    $whatIfState = Get-NovaCliInvocationWhatIfState -WhatIfEnabled:$WhatIfEnabled -MutatingCommonParameters $mutatingCommonParameters -RoutingWhatIfEnabled:$routingState.WhatIfEnabled

    return Get-NovaCliResolvedInvocationContext -Command $routingState.Command -Arguments $routingState.Arguments -CommonParameters $commonParameters -MutatingCommonParameters $mutatingCommonParameters -ModuleName $moduleName -WhatIfEnabled:$whatIfState -CliConfirmEnabled:$cliConfirmEnabled
}
