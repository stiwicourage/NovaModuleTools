BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConvertTo-NovaCliArgumentArray.ps1')
}

Describe 'ConvertTo-NovaCliArgumentArray' {
    It 'returns the provided arguments when bound' {
        $bound = @{Arguments = @('a', 'b')}
        $result = ConvertTo-NovaCliArgumentArray -BoundParameters $bound -Arguments @('a', 'b')
        $result.Count | Should -Be 2
        $result[0] | Should -Be 'a'
    }

    It 'returns an empty array when Arguments was not bound' {
        $result = ConvertTo-NovaCliArgumentArray -BoundParameters @{} -Arguments $null
        ,$result | Should -BeOfType ([System.Array])
        $result.Count | Should -Be 0
    }
}
