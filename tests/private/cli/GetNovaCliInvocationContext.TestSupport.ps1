function Get-NovaCliForwardingParameterSet {param([hashtable]$BoundParameters, [switch]$IncludeShouldProcess)}
function ConvertTo-NovaCliArgumentArray {param([hashtable]$BoundParameters, $Arguments)}
function Assert-NovaCliArgumentSyntax {param($Arguments)}
function Get-NovaCliHelpRequest {param([string]$Command, $Arguments)}
function Get-NovaCliArgumentRoutingState {param([string]$Command, $Arguments)}
function Merge-NovaCliParameterSet {param([hashtable]$BaseParameters, [hashtable]$AdditionalParameters); return $BaseParameters}
function Get-TestNovaCliResolvedInvocationContext {
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
