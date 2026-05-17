function Get-NovaCliForwardingParameterSet {param([hashtable]$BoundParameters, [switch]$IncludeShouldProcess)}
function ConvertTo-NovaCliArgumentArray {param([hashtable]$BoundParameters, $Arguments)}
function Assert-NovaCliArgumentSyntax {param($Arguments)}
function Get-NovaCliHelpRequest {param([string]$Command, $Arguments)}
function Get-NovaCliArgumentRoutingState {param([string]$Command, $Arguments)}
function Merge-NovaCliParameterSet {param([hashtable]$BaseParameters, [hashtable]$AdditionalParameters); return $BaseParameters}

function ConvertFrom-TestInvocationArguments {
    param([object[]]$ArgumentList)

    $values = @{}
    for ($index = 0; $index -lt $ArgumentList.Count; $index += 1) {
        $name = "$($ArgumentList[$index])".TrimStart('-').TrimEnd(':')
        $index += 1
        $values[$name] = $ArgumentList[$index]
    }

    return $values
}

function Get-TestInvocationArgumentValue {
    param(
        [hashtable]$Values,
        [string]$Name
    )

    if ($Values.ContainsKey($Name)) {
        return $Values[$Name]
    }

    return $null
}

function Get-TestNovaCliResolvedInvocationContext {
    $values = ConvertFrom-TestInvocationArguments -ArgumentList $args

    [pscustomobject]@{
        Command = Get-TestInvocationArgumentValue -Values $values -Name 'Command'
        Arguments = @(Get-TestInvocationArgumentValue -Values $values -Name 'Arguments')
        CommonParameters = Get-TestInvocationArgumentValue -Values $values -Name 'CommonParameters'
        MutatingCommonParameters = Get-TestInvocationArgumentValue -Values $values -Name 'MutatingCommonParameters'
        IsHelpRequest = ($null -ne (Get-TestInvocationArgumentValue -Values $values -Name 'HelpRequest'))
        HelpRequest = Get-TestInvocationArgumentValue -Values $values -Name 'HelpRequest'
        ModuleName = Get-TestInvocationArgumentValue -Values $values -Name 'ModuleName'
        WhatIfEnabled = [bool](Get-TestInvocationArgumentValue -Values $values -Name 'WhatIfEnabled')
        CliConfirmEnabled = [bool](Get-TestInvocationArgumentValue -Values $values -Name 'CliConfirmEnabled')
    }
}
