BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/PublishNovaBuiltModuleToDirectory.ps1')
}

Describe 'Publish-NovaBuiltModuleToDirectory' {
    BeforeEach {
        $script:src = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $script:dest = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $sourceModule = Join-Path $script:src 'Sample'
        New-Item -ItemType Directory -Path $sourceModule -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sourceModule 'Sample.psm1') -Value 'x'
        $script:project = [pscustomobject]@{ProjectName='Sample'; OutputModuleDir=$sourceModule}
    }
    AfterEach {
        Remove-Item -LiteralPath $script:src -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:dest -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates the destination directory and copies the module' {
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/Sample.psm1') | Should -BeTrue
    }

    It 'removes the previous module before copy' {
        New-Item -ItemType Directory -Path (Join-Path $script:dest 'Sample') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:dest 'Sample/old.txt') -Value 'old'
        Publish-NovaBuiltModuleToDirectory -ProjectInfo $script:project -ModuleDirectoryPath $script:dest
        Test-Path -LiteralPath (Join-Path $script:dest 'Sample/old.txt') | Should -BeFalse
    }
}
