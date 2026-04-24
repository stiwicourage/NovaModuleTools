function Stop-NovaOperation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Stop-NovaOperation only raises a terminating error and does not mutate repository or runtime state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$ErrorId,
        [Parameter(Mandatory)][System.Management.Automation.ErrorCategory]$Category,
        [AllowNull()]$TargetObject
    )

    throw (New-NovaErrorRecord @PSBoundParameters)
}
