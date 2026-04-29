function Get-NovaShouldProcessForwardingParameter {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    $forwardingParameter = @{}
    if ($WhatIfEnabled) {
        $forwardingParameter.WhatIf = $true
    }

    return $forwardingParameter
}
