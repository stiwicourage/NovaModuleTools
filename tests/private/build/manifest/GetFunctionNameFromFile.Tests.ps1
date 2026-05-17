BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/build/manifest/GetFunctionNameFromFile.ps1')
}

Describe 'Get-FunctionNameFromFile' {
    BeforeEach {
        $script:file = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString('N') + '.ps1')
    }

    AfterEach {
        Remove-Item -LiteralPath $script:file -ErrorAction SilentlyContinue
    }

    It 'returns the function name parsed from the file' {
        Set-Content -LiteralPath $script:file -Value 'function Get-Demo { param() }'

        Get-FunctionNameFromFile -filePath $script:file | Should -Be 'Get-Demo'
    }

    It 'returns an empty string when the file does not exist' {
        $missing = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N') + '.ps1')

        Get-FunctionNameFromFile -filePath $missing | Should -Be ''
    }
}
