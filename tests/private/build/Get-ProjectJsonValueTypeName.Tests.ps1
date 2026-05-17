BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/Get-ProjectJsonValueTypeName.ps1')
}

Describe 'Get-ProjectJsonValueTypeName' {
    It 'returns null for a null value' {
        Get-ProjectJsonValueTypeName -Value $null | Should -Be 'null'
    }

    It 'returns the full type name for a string' {
        Get-ProjectJsonValueTypeName -Value 'text' | Should -Be 'System.String'
    }

    It 'returns the full type name for an int' {
        Get-ProjectJsonValueTypeName -Value 42 | Should -Be 'System.Int32'
    }

    It 'returns the full type name for a hashtable' {
        Get-ProjectJsonValueTypeName -Value @{a = 1} | Should -Be 'System.Collections.Hashtable'
    }
}
