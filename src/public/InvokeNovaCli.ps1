function Invoke-NovaCli {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'The public CLI entrypoint forwards WhatIf/Confirm semantics to the routed commands that own the actual ShouldProcess decisions.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Position = 0)]
        [string]$Command = '--help',
        [Parameter(Position = 1, ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $commandName = if ([string]::IsNullOrWhiteSpace($Command)) {
        '--help'
    } else {
        $Command
    }

    $invocationRequest = [pscustomobject]@{
        Command = $commandName
        BoundParameters = $PSBoundParameters
        Arguments = $Arguments
    }

    $invocationContext = Get-NovaCliInvocationContext -InvocationRequest $invocationRequest -WhatIfEnabled:$WhatIfPreference
    return Invoke-NovaCliCommandRoute -InvocationContext $invocationContext
}
