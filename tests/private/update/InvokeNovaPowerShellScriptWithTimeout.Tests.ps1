BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaPowerShellScriptWithTimeout.ps1')
}

Describe 'Invoke-NovaPowerShellScriptWithTimeout' {
    It 'returns the script result before the timeout elapses' {
        $result = Invoke-NovaPowerShellScriptWithTimeout -Script 'param($x) "hello-$x"' -ArgumentList @('world') -TimeoutMilliseconds 5000
        $result | Should -Be 'hello-world'
    }

    It 'returns null when the script exceeds the timeout' {
        $result = Invoke-NovaPowerShellScriptWithTimeout -Script 'Start-Sleep -Seconds 5; "late"' -TimeoutMilliseconds 100
        $result | Should -BeNullOrEmpty
    }

    It 'returns null when the script throws' {
        $result = Invoke-NovaPowerShellScriptWithTimeout -Script 'throw "boom"' -TimeoutMilliseconds 5000
        $result | Should -BeNullOrEmpty
    }

    It 'disposes the PowerShell instance via the factory' {
        $disposed = [ref]$false
        $factory = {
            $ps = [powershell]::Create()
            $script:capturedPs = $ps
            $ps
        }
        $null = Invoke-NovaPowerShellScriptWithTimeout -Script '"ok"' -PowerShellFactory $factory -TimeoutMilliseconds 5000
        { $script:capturedPs.AddScript('x') } | Should -Throw
    }
}
