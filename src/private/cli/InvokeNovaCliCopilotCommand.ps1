function Invoke-NovaCliCopilotCommand {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$CommonParameters,
        [Parameter(Mandatory)][hashtable]$MutatingCommonParameters
    )

    $options = ConvertFrom-NovaCopilotCliArgument -Arguments $Arguments
    $invocationParameters = Merge-NovaCliParameterSet -BaseParameters @{} -AdditionalParameters $CommonParameters
    $invocationParameters = Merge-NovaCliParameterSet -BaseParameters $invocationParameters -AdditionalParameters $MutatingCommonParameters
    $invocationParameters = Merge-NovaCliParameterSet -BaseParameters $invocationParameters -AdditionalParameters $options

    return Invoke-NovaAgenticCopilotScaffold @invocationParameters
}
