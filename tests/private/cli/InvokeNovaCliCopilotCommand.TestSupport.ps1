function ConvertFrom-NovaCopilotCliArgument {
    param([string[]]$Arguments)
    return @{Path = '/tmp/repo'; ShortName = 'NMT'}
}

function Invoke-NovaAgenticCopilotScaffold {
    param($Path, $ShortName, $Verbose, $WhatIf)
    return [pscustomobject]@{
        Path = $Path
        ShortName = $ShortName
        Verbose = [bool]$Verbose
        WhatIf = [bool]$WhatIf
    }
}
