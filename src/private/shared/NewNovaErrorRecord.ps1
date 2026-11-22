function New-NovaErrorRecord {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaErrorRecord only constructs and returns an ErrorRecord object.')]
    [CmdletBinding()]
    [OutputType([System.Management.Automation.ErrorRecord])]
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$ErrorId,
        [Parameter(Mandatory)][System.Management.Automation.ErrorCategory]$Category,
        [AllowNull()]$TargetObject
    )

    $resolvedException = [System.InvalidOperationException]::new($Message)

    return [System.Management.Automation.ErrorRecord]::new(
            $resolvedException,
            $ErrorId,
            $Category,
            $TargetObject
    )
}
