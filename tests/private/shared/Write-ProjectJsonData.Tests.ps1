BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/Write-ProjectJsonData.ps1')
}

Describe 'Write-ProjectJsonData' {
    BeforeEach {
        $script:tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString('N') + '.json')
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempFile -ErrorAction SilentlyContinue
    }

    It 'writes the hashtable as JSON to the given path' {
        Write-ProjectJsonData -ProjectJsonPath $script:tempFile -Data @{Name = 'Demo'; Version = '1.0.0'}

        $content = Get-Content -LiteralPath $script:tempFile -Raw | ConvertFrom-Json
        $content.Name | Should -Be 'Demo'
        $content.Version | Should -Be '1.0.0'
    }
}
