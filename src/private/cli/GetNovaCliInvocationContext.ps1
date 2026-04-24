function Get-NovaCliInvocationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [AllowNull()][string[]]$Arguments,
        [switch]$WhatIfEnabled
    )

    $commonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $BoundParameters
    $mutatingCommonParameters = Get-NovaCliForwardingParameterSet -BoundParameters $BoundParameters -IncludeShouldProcess
    $normalizedArguments = ConvertTo-NovaCliArgumentArray -BoundParameters $BoundParameters -Arguments $Arguments

    return [pscustomobject]@{
        Command = $Command
        Arguments = $normalizedArguments
        CommonParameters = $commonParameters
        MutatingCommonParameters = $mutatingCommonParameters
        IsHelpRequest = Test-NovaCliHelpRequest -Arguments $normalizedArguments
        ModuleName = $ExecutionContext.SessionState.Module.Name
        WhatIfEnabled = $WhatIfEnabled.IsPresent
    }
}
