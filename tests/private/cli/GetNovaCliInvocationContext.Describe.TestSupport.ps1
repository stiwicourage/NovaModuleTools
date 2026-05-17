function Get-NovaCliResolvedInvocationContext {
    param($Command, $Arguments, $CommonParameters, $MutatingCommonParameters, $ModuleName, $WhatIfEnabled, $CliConfirmEnabled, $HelpRequest)

    [pscustomobject]@{
        Command = $Command
        Arguments = @($Arguments)
        CommonParameters = $CommonParameters
        MutatingCommonParameters = $MutatingCommonParameters
        IsHelpRequest = ($null -ne $HelpRequest)
        HelpRequest = $HelpRequest
        ModuleName = $ModuleName
        WhatIfEnabled = [bool]$WhatIfEnabled
        CliConfirmEnabled = [bool]$CliConfirmEnabled
    }
}
