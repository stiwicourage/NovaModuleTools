BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/AddScriptFileContentToModuleBuilder.ps1')

    function Get-NormalizedRelativePath {param([string]$Root, [string]$FullName)}
}

Describe 'Add-ScriptFileContentToModuleBuilder' {
    BeforeEach {
        $script:tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [Guid]::NewGuid().ToString('N') + '.ps1')
        Set-Content -LiteralPath $script:tempFile -Value 'function Get-Foo {}'
        $script:fileInfo = Get-Item -LiteralPath $script:tempFile
        $script:builder = [System.Text.StringBuilder]::new()
    }

    AfterEach {
        Remove-Item -LiteralPath $script:tempFile -ErrorAction SilentlyContinue
    }

    It 'prepends a source comment when SetSourcePath is enabled' {
        Mock Get-NormalizedRelativePath {return 'src/public/Get-Foo.ps1'}
        $info = [pscustomobject]@{SetSourcePath = $true; ProjectRoot = '/proj'}

        Add-ScriptFileContentToModuleBuilder -Builder $script:builder -ProjectInfo $info -File $script:fileInfo

        $script:builder.ToString() | Should -Match '# Source: src/public/Get-Foo\.ps1'
        $script:builder.ToString() | Should -Match 'function Get-Foo'
    }

    It 'skips the source comment when SetSourcePath is disabled' {
        $info = [pscustomobject]@{SetSourcePath = $false; ProjectRoot = '/proj'}

        Add-ScriptFileContentToModuleBuilder -Builder $script:builder -ProjectInfo $info -File $script:fileInfo

        $script:builder.ToString() | Should -Not -Match '# Source:'
        $script:builder.ToString() | Should -Match 'function Get-Foo'
    }
}
