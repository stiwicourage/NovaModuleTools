BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetProjectResourceItemList.ps1')
}

Describe 'Get-ProjectResourceItemList' {
    BeforeEach {
        $script:tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:tempFolder -Force
    }

    AfterEach {
        if (Test-Path -LiteralPath $script:tempFolder) {
            Remove-Item -LiteralPath $script:tempFolder -Recurse -Force
        }
    }

    It 'returns the items found in the resource folder' {
        $null = New-Item -ItemType File -Path (Join-Path $script:tempFolder 'a.txt') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $script:tempFolder 'sub') -Force

        $result = Get-ProjectResourceItemList -ResourceFolder $script:tempFolder

        $result.Count | Should -Be 2
    }

    It 'returns an empty array when the folder does not exist' {
        $missing = Join-Path $script:tempFolder 'missing'

        $result = Get-ProjectResourceItemList -ResourceFolder $missing

        @($result).Count | Should -Be 0
    }
}
