BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/NewNovaTestDynamicParameterDictionary.ps1')
}

Describe 'New-NovaTestDynamicParameterDictionary' {
    It 'returns a RuntimeDefinedParameterDictionary' {
        $result = New-NovaTestDynamicParameterDictionary
        $result | Should -BeOfType [System.Management.Automation.RuntimeDefinedParameterDictionary]
    }

    It 'exposes the expected switch parameters' {
        $result = New-NovaTestDynamicParameterDictionary
        $result.Keys | Should -Contain 'Build'
        $result.Keys | Should -Contain 'OverrideWarning'
        $result['Build'].ParameterType | Should -Be ([switch])
        $result['OverrideWarning'].ParameterType | Should -Be ([switch])
    }
}
