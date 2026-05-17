BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/NewNovaErrorRecord.ps1')
    . (Join-Path $projectRoot 'src/private/shared/StopNovaOperation.ps1')
}

Describe 'Stop-NovaOperation' {
    It 'throws an ErrorRecord built from the provided values' {
        $thrown = $null
        try {
            Stop-NovaOperation -Message 'fail' -ErrorId 'Nova.Test.Fail' -Category InvalidData -TargetObject 'x'
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.FullyQualifiedErrorId | Should -Match 'Nova\.Test\.Fail'
    }
}
