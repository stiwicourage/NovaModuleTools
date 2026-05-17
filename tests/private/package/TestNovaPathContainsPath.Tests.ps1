BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/TestNovaPathContainsPath.ps1')
}

Describe 'Test-NovaPathContainsPath' {
    BeforeEach {
        $script:parent = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $script:child = Join-Path $script:parent 'sub/file'
        New-Item -ItemType Directory -Path (Join-Path $script:parent 'sub') -Force | Out-Null
        Set-Content -LiteralPath $script:child -Value 'x'
    }
    AfterEach {
        Remove-Item -LiteralPath $script:parent -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns true when child equals parent' {
        Test-NovaPathContainsPath -ParentPath $script:parent -ChildPath $script:parent | Should -BeTrue
    }

    It 'returns true when child is nested under parent' {
        Test-NovaPathContainsPath -ParentPath $script:parent -ChildPath $script:child | Should -BeTrue
    }

    It 'returns false when child is outside parent' {
        Test-NovaPathContainsPath -ParentPath $script:parent -ChildPath ([System.IO.Path]::GetTempPath()) | Should -BeFalse
    }
}
