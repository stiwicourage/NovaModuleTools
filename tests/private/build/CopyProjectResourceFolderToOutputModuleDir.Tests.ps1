BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/CopyProjectResourceFolderToOutputModuleDir.ps1')
}

Describe 'Copy-ProjectResourceFolderToOutputModuleDir' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $script:source = Join-Path $script:root 'resources'
        $script:target = Join-Path $script:root 'dist'
        $null = New-Item -ItemType Directory -Path $script:source -Force
        $null = New-Item -ItemType Directory -Path $script:target -Force
        Set-Content -LiteralPath (Join-Path $script:source 'file.txt') -Value 'hello'
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'recursively copies the resource folder into the output module directory' {
        Copy-ProjectResourceFolderToOutputModuleDir -ResourceFolder $script:source -OutputModuleDir $script:target

        $copied = Join-Path $script:target 'resources/file.txt'
        Test-Path -LiteralPath $copied | Should -BeTrue
    }
}
