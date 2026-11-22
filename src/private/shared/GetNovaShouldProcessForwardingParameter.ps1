function Get-NovaShouldProcessForwardingParameter {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [switch]$WhatIfEnabled
    )

    $forwardingParameter = @{}
    if ($WhatIfEnabled) {
        $forwardingParameter.WhatIf = $true
    }

    return $forwardingParameter
}
