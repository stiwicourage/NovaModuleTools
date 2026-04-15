function Get-NovaShouldProcessForwardingParameter {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    $forwardingParameter = @{Confirm = $false}
    if ($WhatIfEnabled) {
        $forwardingParameter.WhatIf = $true
    }

    return $forwardingParameter
}

