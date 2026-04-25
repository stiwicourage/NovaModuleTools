function Invoke-NovaCliInitCommand {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        Stop-NovaOperation -Message "The 'nova init' CLI command does not support '--what-if'/'-w'. Run 'nova init' or 'nova init --path <path>' without preview mode." -ErrorId 'Nova.Validation.UnsupportedInitCliWhatIf' -Category InvalidOperation -TargetObject 'WhatIf'
    }

    $options = ConvertFrom-NovaInitCliArgument -Arguments $Arguments
    return Initialize-NovaModule @options @ForwardedParameters
}

