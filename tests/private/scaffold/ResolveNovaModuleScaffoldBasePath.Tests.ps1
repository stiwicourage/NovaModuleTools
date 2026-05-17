BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/ResolveNovaModuleScaffoldBasePath.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'Resolve-NovaModuleScaffoldBasePath' {
    BeforeAll {
        $script:tempDir = (Resolve-Path -LiteralPath (New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().Guid)))).Path
    }

    AfterAll {
        Remove-Item -LiteralPath $script:tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns the full resolved path when the directory exists' {
        $result = Resolve-NovaModuleScaffoldBasePath -Path $script:tempDir
        $result | Should -Be ([System.IO.Path]::GetFullPath($script:tempDir))
    }

    It 'normalizes mixed separators before resolving' {
        $mixed = $script:tempDir -replace '/', '\'
        $result = Resolve-NovaModuleScaffoldBasePath -Path $mixed
        $result | Should -Be ([System.IO.Path]::GetFullPath($script:tempDir))
    }

    It 'stops the operation when the path does not exist' {
        $missing = Join-Path $script:tempDir ('missing-' + [guid]::NewGuid().Guid)
        {Resolve-NovaModuleScaffoldBasePath -Path $missing} | Should -Throw '*Not a valid path*'
    }
}
