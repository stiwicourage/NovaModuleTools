BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaBuildCommandParameterMap.ps1')
}

Describe 'Get-NovaBuildCommandParameterMap' {
    It 'returns an empty hashtable when no workflow parameters are passed' {
        $result = Get-NovaBuildCommandParameterMap

        $result | Should -BeOfType [hashtable]
        $result.Keys.Count | Should -Be 0
    }

    It 'copies all workflow parameters into the new hashtable' {
        $result = Get-NovaBuildCommandParameterMap -WorkflowParams @{Path = '/p'; CI = $true}

        $result.Path | Should -Be '/p'
        $result.CI | Should -BeTrue
    }

    It 'sets OverrideWarning when the override switch is set' {
        $result = Get-NovaBuildCommandParameterMap -WorkflowParams @{Path = '/p'} -OverrideWarningRequested

        $result.OverrideWarning | Should -BeTrue
    }

    It 'does not add OverrideWarning when not requested' {
        $result = Get-NovaBuildCommandParameterMap -WorkflowParams @{Path = '/p'}

        $result.ContainsKey('OverrideWarning') | Should -BeFalse
    }
}
