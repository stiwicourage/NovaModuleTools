BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/build/manifest/GetAliasNameFromFunction.ps1')
}

Describe 'Get-AliasInFunctionFromFile' {
    BeforeEach {
        $script:file = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString('N') + '.ps1')
    }

    AfterEach {
        Remove-Item -LiteralPath $script:file -ErrorAction SilentlyContinue
    }

    It 'returns the alias values declared on the function' {
        $body = @'
function Get-Demo {
    [Alias('gd', 'demo')]
    param()
}
'@
        Set-Content -LiteralPath $script:file -Value $body

        $aliases = Get-AliasInFunctionFromFile -filePath $script:file

        $aliases | Should -Contain 'gd'
        $aliases | Should -Contain 'demo'
    }

    It 'returns nothing when the function has no Alias attribute' {
        Set-Content -LiteralPath $script:file -Value 'function Get-Demo { param() }'

        $aliases = Get-AliasInFunctionFromFile -filePath $script:file

        @($aliases | Where-Object {$_}).Count | Should -Be 0
    }

    It 'returns nothing when the file does not exist' {
        $missing = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N') + '.ps1')

        $result = Get-AliasInFunctionFromFile -filePath $missing

        $null -eq $result -or @($result).Count -eq 0 | Should -BeTrue
    }
}
