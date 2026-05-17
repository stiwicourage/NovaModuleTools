BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetProjectResourceFolderPath.ps1')
}

Describe 'Get-ProjectResourceFolderPath' {
    It 'returns src/resources joined to the project root' {
        $result = Get-ProjectResourceFolderPath -ProjectRoot '/tmp/proj'

        $result | Should -Be ([System.IO.Path]::Join('/tmp/proj', 'src', 'resources'))
    }
}
