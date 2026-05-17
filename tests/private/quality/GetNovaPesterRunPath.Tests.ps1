BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterRunPath.ps1')
}

Describe 'Get-NovaPesterRunPath' {
    It 'returns the tests directory when BuildRecursiveFolders is enabled' {
        $info = [pscustomobject]@{BuildRecursiveFolders = $true; TestsDir = '/p/tests'}
        Get-NovaPesterRunPath -ProjectInfo $info | Should -Be '/p/tests'
    }

    It 'returns the *.Tests.ps1 glob when BuildRecursiveFolders is disabled' {
        $info = [pscustomobject]@{BuildRecursiveFolders = $false; TestsDir = '/p/tests'}
        Get-NovaPesterRunPath -ProjectInfo $info | Should -Be ([System.IO.Path]::Join('/p/tests', '*.Tests.ps1'))
    }
}
