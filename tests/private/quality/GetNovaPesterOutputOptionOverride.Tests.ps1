BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterOutputOptionOverride.ps1')
}

Describe 'Get-NovaPesterOutputOptionOverride' {
    It 'returns null when the config has no Output property' {
        $config = [pscustomobject]@{Other='x'}
        Get-NovaPesterOutputOptionOverride -PesterConfig $config -BoundParameters @{} | Should -BeNull
    }

    It 'sets Verbosity only when bound and RenderMode only when bound' {
        $config = [pscustomobject]@{Output=$null}
        $result = Get-NovaPesterOutputOptionOverride -PesterConfig $config -BoundParameters @{OutputVerbosity='Detailed'} -OutputVerbosity 'Detailed' -OutputRenderMode 'ConsoleAnsi'
        $result.Verbosity | Should -Be 'Detailed'
        $result.RenderMode | Should -BeNull
    }

    It 'sets both when both are bound' {
        $config = [pscustomobject]@{Output=$null}
        $result = Get-NovaPesterOutputOptionOverride -PesterConfig $config -BoundParameters @{OutputVerbosity='Normal'; OutputRenderMode='Plaintext'} -OutputVerbosity 'Normal' -OutputRenderMode 'Plaintext'
        $result.Verbosity | Should -Be 'Normal'
        $result.RenderMode | Should -Be 'Plaintext'
    }
}
