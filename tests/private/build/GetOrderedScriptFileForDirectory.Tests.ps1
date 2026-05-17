BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetOrderedScriptFileForDirectory.ps1')

    function Get-NormalizedRelativePath {
        param([string]$Root, [string]$FullName)
        return [System.IO.Path]::GetRelativePath($Root, $FullName) -replace '\\', '/'
    }
}

Describe 'Get-OrderedScriptFileForDirectory' {
    BeforeEach {
        $script:root = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
        $null = New-Item -ItemType Directory -Path $script:root -Force
    }

    AfterEach {
        Remove-Item -LiteralPath $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns an empty array when the directory does not exist' {
        $result = Get-OrderedScriptFileForDirectory -Directory (Join-Path $script:root 'missing') -ProjectRoot $script:root -Recurse $false

        @($result).Count | Should -Be 0
    }

    It 'returns ps1 files sorted by normalized relative path' {
        Set-Content -LiteralPath (Join-Path $script:root 'B.ps1') -Value '#'
        Set-Content -LiteralPath (Join-Path $script:root 'A.ps1') -Value '#'

        $result = Get-OrderedScriptFileForDirectory -Directory $script:root -ProjectRoot $script:root -Recurse $false

        $result[0].Name | Should -Be 'A.ps1'
        $result[1].Name | Should -Be 'B.ps1'
    }

    It 'recurses when Recurse is true' {
        $sub = Join-Path $script:root 'sub'
        $null = New-Item -ItemType Directory -Path $sub -Force
        Set-Content -LiteralPath (Join-Path $sub 'C.ps1') -Value '#'

        $result = Get-OrderedScriptFileForDirectory -Directory $script:root -ProjectRoot $script:root -Recurse $true

        $result.Name | Should -Contain 'C.ps1'
    }

    It 'ignores subfolders when Recurse is false' {
        $sub = Join-Path $script:root 'sub'
        $null = New-Item -ItemType Directory -Path $sub -Force
        Set-Content -LiteralPath (Join-Path $sub 'C.ps1') -Value '#'

        $result = Get-OrderedScriptFileForDirectory -Directory $script:root -ProjectRoot $script:root -Recurse $false

        @($result).Count | Should -Be 0
    }
}
