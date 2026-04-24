function Invoke-NovaCli {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'The public CLI entrypoint forwards WhatIf/Confirm semantics to the routed commands that own the actual ShouldProcess decisions.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('nova')]
    param(
        [Parameter(Position = 0)]
        [string]$Command = '--help',
        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $invocationContext = Get-NovaCliInvocationContext -Command $Command -BoundParameters $PSBoundParameters -Arguments $Arguments -WhatIfEnabled:$WhatIfPreference
    return Invoke-NovaCliCommandRoute -InvocationContext $invocationContext
}
