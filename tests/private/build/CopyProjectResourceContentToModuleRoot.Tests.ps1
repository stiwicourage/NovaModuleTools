BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/CopyProjectResourceContentToModuleRoot.ps1')
}

Describe 'Copy-ProjectResourceContentToModuleRoot' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $script:source = Join-Path $script:root 'resources'
        $script:target = Join-Path $script:root 'dist'
        $null = New-Item -ItemType Directory -Path $script:source -Force
        $null = New-Item -ItemType Directory -Path $script:target -Force
        Set-Content -LiteralPath (Join-Path $script:source 'a.txt') -Value 'A'
        $null = New-Item -ItemType Directory -Path (Join-Path $script:source 'sub') -Force
        Set-Content -LiteralPath (Join-Path $script:source 'sub/b.txt') -Value 'B'
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'copies each item directly into the output module directory' {
        $items = Get-ChildItem -Path $script:source

        Copy-ProjectResourceContentToModuleRoot -ItemList $items -OutputModuleDir $script:target

        Test-Path -LiteralPath (Join-Path $script:target 'a.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:target 'sub/b.txt') | Should -BeTrue
    }
}
