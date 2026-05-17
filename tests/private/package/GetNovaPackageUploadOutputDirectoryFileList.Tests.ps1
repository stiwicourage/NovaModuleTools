BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadOutputDirectoryFileList.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Get-NovaPackageUploadOutputDirectoryFileList' {
    BeforeEach {
        $script:dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:dir | Out-Null
    }
    AfterEach {
        Remove-Item -LiteralPath $script:dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns matching files sorted by name' {
        Set-Content -LiteralPath (Join-Path $script:dir 'b.nupkg') -Value '1'
        Set-Content -LiteralPath (Join-Path $script:dir 'a.nupkg') -Value '2'
        Set-Content -LiteralPath (Join-Path $script:dir 'c.zip') -Value '3'
        $files = Get-NovaPackageUploadOutputDirectoryFileList -OutputDirectory $script:dir -SearchPattern '*.nupkg' -PackageType 'NuGet'
        @($files).Count | Should -Be 2
        $files[0].Name | Should -Be 'a.nupkg'
    }

    It 'throws when no files match the pattern' {
        {Get-NovaPackageUploadOutputDirectoryFileList -OutputDirectory $script:dir -SearchPattern '*.nupkg' -PackageType 'NuGet'} | Should -Throw '*Package file not found*'
    }
}
