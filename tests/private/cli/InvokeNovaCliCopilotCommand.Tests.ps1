BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliCopilotCommand.ps1')

    function ConvertFrom-NovaCopilotCliArgument {
        param([string[]]$Arguments) return @{Path = '/tmp/repo'; ShortName = 'NMT'}
    }
    function Merge-NovaCliParameterSet {
        param([hashtable]$BaseParameters, [hashtable]$AdditionalParameters)
        foreach ($name in $AdditionalParameters.Keys) {
            $BaseParameters[$name] = $AdditionalParameters[$name]
        }
        return $BaseParameters
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
}

Describe 'Invoke-NovaCliCopilotCommand' {
    It 'merges parsed options with forwarded common parameters' {
        $result = Invoke-NovaCliCopilotCommand -Arguments @('--short-name', 'NMT') -CommonParameters @{Verbose = $true} -MutatingCommonParameters @{WhatIf = $true}

        $result.Path | Should -Be '/tmp/repo'
        $result.ShortName | Should -Be 'NMT'
        $result.Verbose | Should -BeTrue
        $result.WhatIf | Should -BeTrue
    }
}
