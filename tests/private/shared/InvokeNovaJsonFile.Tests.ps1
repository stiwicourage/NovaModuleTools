BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/InvokeNovaJsonFile.ps1')
}

Describe 'Read-NovaJsonFileData' {
    BeforeEach {
        $script:tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString('N') + '.json')
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempFile -ErrorAction SilentlyContinue
    }

    It 'returns null when the file is missing' {
        Read-NovaJsonFileData -LiteralPath $script:tempFile | Should -BeNullOrEmpty
    }

    It 'returns the parsed object when JSON is valid' {
        Set-Content -LiteralPath $script:tempFile -Value '{"Name": "Demo"}'

        $result = Read-NovaJsonFileData -LiteralPath $script:tempFile

        $result.Name | Should -Be 'Demo'
    }

    It 'returns null when the JSON is invalid' {
        Set-Content -LiteralPath $script:tempFile -Value '{not json}'

        Read-NovaJsonFileData -LiteralPath $script:tempFile | Should -BeNullOrEmpty
    }
}

Describe 'Initialize-NovaDirectoryPath' {
    It 'creates a missing directory' {
        $target = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        try {
            Initialize-NovaDirectoryPath -Path $target

            Test-Path -LiteralPath $target -PathType Container | Should -BeTrue
        } finally {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'is a no-op when the directory already exists' {
        $target = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $target -Force
        try {
            {Initialize-NovaDirectoryPath -Path $target} | Should -Not -Throw
        } finally {
            Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'Write-NovaJsonFileData' {
    It 'creates parent directories and writes a JSON payload' {
        $root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $file = Join-Path $root 'nested/data.json'
        try {
            Write-NovaJsonFileData -LiteralPath $file -Value @{Name = 'Demo'}

            Test-Path -LiteralPath $file | Should -BeTrue
            (Get-Content -LiteralPath $file -Raw | ConvertFrom-Json).Name | Should -Be 'Demo'
        } finally {
            Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
