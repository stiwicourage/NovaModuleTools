function New-TestPesterConfigStub {
    [CmdletBinding()]
    param(
        [switch]$IncludeOutput
    )

    $config = [ordered]@{
        'Run' = [pscustomobject]@{
            'Path' = $null
            'PassThru' = $false
            'Exit' = $false
            'Throw' = $false
        }
        'Filter' = [pscustomobject]@{
            'Tag' = @()
            'ExcludeTag' = @()
        }
        'TestResult' = [pscustomobject]@{
            'OutputPath' = $null
        }
    }

    if ($IncludeOutput) {
        $config.Output = [pscustomobject]@{
            'Verbosity' = 'Detailed'
            'RenderMode' = 'Auto'
        }
    }

    return [pscustomobject]$config
}

