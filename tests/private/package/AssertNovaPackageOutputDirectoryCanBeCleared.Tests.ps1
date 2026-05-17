BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/AssertNovaPackageOutputDirectoryCanBeCleared.ps1')

    . (Join-Path $PSScriptRoot 'AssertNovaPackageOutputDirectoryCanBeCleared.TestSupport.ps1')
}

Describe 'Assert-NovaPackageOutputDirectoryCanBeCleared' {
    It 'returns silently for a normal directory that is not a parent of protected paths' {
        $project = [pscustomobject]@{ProjectRoot='/proj'; OutputModuleDir='/proj/dist'}
        {Assert-NovaPackageOutputDirectoryCanBeCleared -ProjectInfo $project -OutputDirectory ([System.IO.Path]::GetTempPath())} | Should -Not -Throw
    }

    It 'throws when output directory contains a protected path' {
        Mock Test-NovaPathContainsPath {return $true}
        $project = [pscustomobject]@{ProjectRoot='/proj'; OutputModuleDir='/proj/dist'}
        {Assert-NovaPackageOutputDirectoryCanBeCleared -ProjectInfo $project -OutputDirectory ([System.IO.Path]::GetTempPath())} | Should -Throw '*required project content*'
    }

    It 'throws when the resolved output directory is a filesystem root' {
        $root = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()))
        if (-not $root) {Set-ItResult -Skipped -Because 'No root path available on this platform'}
        $project = [pscustomobject]@{ProjectRoot='/proj'; OutputModuleDir='/proj/dist'}
        {Assert-NovaPackageOutputDirectoryCanBeCleared -ProjectInfo $project -OutputDirectory $root} | Should -Throw '*root*'
    }
}
