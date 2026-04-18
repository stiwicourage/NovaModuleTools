function Invoke-NovaPowerShellScriptWithTimeout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Script,
        [object[]]$ArgumentList = @(),
        [int]$TimeoutMilliseconds = 3000
    )

    $powershell = [powershell]::Create()
    try {
        $null = $powershell.AddScript($Script)
        foreach ($argument in $ArgumentList) {
            $null = $powershell.AddArgument($argument)
        }

        $asyncResult = $powershell.BeginInvoke()
        if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMilliseconds)) {
            try {
                $powershell.Stop()
            }
            catch {
                $null = $_
            }

            return $null
        }

        try {
            return $powershell.EndInvoke($asyncResult) | Select-Object -First 1
        }
        catch {
            return $null
        }
    }
    finally {
        $powershell.Dispose()
    }
}
