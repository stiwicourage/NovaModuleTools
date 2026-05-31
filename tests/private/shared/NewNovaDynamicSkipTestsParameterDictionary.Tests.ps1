BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/NewNovaDynamicSkipTestsParameterDictionary.ps1')
}

Describe 'Get-NovaDynamicParameterAttributeCollection' {
    It 'returns a single default attribute when no parameter sets supplied' {
        $col = @(Get-NovaDynamicParameterAttributeCollection)
        $col.Count | Should -Be 1
        $col[0].ParameterSetName | Should -Be '__AllParameterSets'
        $col[0].Mandatory | Should -BeFalse
    }
    It 'returns one attribute per parameter set name' {
        $col = @(Get-NovaDynamicParameterAttributeCollection -ParameterSetNameList @('A','B') -Mandatory)
        $col.Count | Should -Be 2
        $col[0].ParameterSetName | Should -Be 'A'
        $col[1].ParameterSetName | Should -Be 'B'
        $col[0].Mandatory | Should -BeTrue
    }
}

Describe 'Add-NovaDynamicTypedParameter' {
    It 'adds a switch parameter with the right type' {
        $dict = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        Add-NovaDynamicTypedParameter -ParameterDictionary $dict -Name 'X' -ParameterType ([switch])
        $dict['X'].ParameterType | Should -Be ([switch])
    }
    It 'adds a string parameter with the right type' {
        $dict = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        Add-NovaDynamicTypedParameter -ParameterDictionary $dict -Name 'Y' -ParameterType ([string]) -ParameterSetNameList @('S')
        $dict['Y'].ParameterType | Should -Be ([string])
    }
    It 'adds a hashtable parameter with the right type' {
        $dict = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        Add-NovaDynamicTypedParameter -ParameterDictionary $dict -Name 'Z' -ParameterType ([hashtable]) -Mandatory
        $dict['Z'].ParameterType | Should -Be ([hashtable])
    }
}

Describe 'Get-NovaDynamicDeliveryParameterDictionary' {
    It 'contains the three core switches' {
        $dict = Get-NovaDynamicDeliveryParameterDictionary
        $dict.ContainsKey('SkipTests') | Should -BeTrue
        $dict.ContainsKey('ContinuousIntegration') | Should -BeTrue
        $dict.ContainsKey('OverrideWarning') | Should -BeTrue
    }
}

Describe 'Get-NovaDynamicOverrideWarningParameterDictionary' {
    It 'contains only the OverrideWarning switch' {
        $dict = Get-NovaDynamicOverrideWarningParameterDictionary
        $dict.Keys | Should -Be @('OverrideWarning')
        $dict['OverrideWarning'].ParameterType | Should -Be ([switch])
    }
}

Describe 'Get-NovaDynamicReleaseParameterDictionary' {
    It 'extends the delivery dictionary with Path and PublishOption' {
        $dict = Get-NovaDynamicReleaseParameterDictionary
        $dict.ContainsKey('SkipTests') | Should -BeTrue
        $dict.ContainsKey('Path') | Should -BeTrue
        $dict.ContainsKey('PublishOption') | Should -BeTrue
        $dict['PublishOption'].ParameterType | Should -Be ([hashtable])
    }
}
