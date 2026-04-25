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
    $routingState = Get-NovaCliArgumentRoutingState -Command $InvocationRequest.Command -Arguments $normalizedArguments
    $cliConfirmEnabled = $false

    if ( $mutatingCommonParameters.ContainsKey('Confirm')) {
        $cliConfirmEnabled = [bool]$mutatingCommonParameters.Confirm
        $mutatingCommonParameters.Remove('Confirm')
    }

    if ( $routingState.ForwardedParameters.ContainsKey('Verbose')) {
        $commonParameters.Verbose = $true
    }

    $mutatingCommonParameters = Merge-NovaCliParameterSet -BaseParameters $mutatingCommonParameters -AdditionalParameters $routingState.ForwardedParameters
    $cliConfirmEnabled = $cliConfirmEnabled -or $routingState.CliConfirmEnabled

    return [pscustomobject]@{
        Command = $routingState.Command
        Arguments = $routingState.Arguments
        CommonParameters = $commonParameters
        MutatingCommonParameters = $mutatingCommonParameters
        IsHelpRequest = Test-NovaCliHelpRequest -Arguments $routingState.Arguments
        ModuleName = $ExecutionContext.SessionState.Module.Name
        WhatIfEnabled = $WhatIfEnabled.IsPresent -or $routingState.WhatIfEnabled -or $mutatingCommonParameters.ContainsKey('WhatIf')
        CliConfirmEnabled = $cliConfirmEnabled
    }
}
