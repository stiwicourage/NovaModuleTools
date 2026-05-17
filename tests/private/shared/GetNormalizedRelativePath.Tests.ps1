BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNormalizedRelativePath.ps1')
}

Describe 'Get-NormalizedRelativePath' {
    It 'returns the relative path with forward slashes' {
        $root = [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        $full = [System.IO.Path]::Combine($root, 'a', 'b', 'c.txt')

        $result = Get-NormalizedRelativePath -Root $root -FullName $full

        $result | Should -Be 'a/b/c.txt'
    }

    It 'returns . when the path equals the root' {
        $root = [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar)

        Get-NormalizedRelativePath -Root $root -FullName $root | Should -Be '.'
    }
}
