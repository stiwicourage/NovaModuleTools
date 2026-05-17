BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/Format-ProjectJsonValue.ps1')
}

Describe 'Format-ProjectJsonValue' {
    It 'returns null for a null value' {
        Format-ProjectJsonValue -Value $null | Should -Be 'null'
    }

    It 'returns compact JSON for a string' {
        Format-ProjectJsonValue -Value 'text' | Should -Be '"text"'
    }

    It 'returns compact JSON for an int' {
        Format-ProjectJsonValue -Value 42 | Should -Be '42'
    }

    It 'returns compact JSON for a hashtable' {
        $result = Format-ProjectJsonValue -Value ([ordered]@{a = 1; b = 'two'})
        $result | Should -Match '"a"\s*:\s*1'
        $result | Should -Match '"b"\s*:\s*"two"'
    }

    It 'falls back to string representation when serialization fails' {
        $stub = [pscustomobject]@{Label = 'unserializable'}
        $stub.PSObject.Members.Add(
                [System.Management.Automation.PSScriptMethod]::new('ToString', {'unserializable-fallback'})
        )
        Mock ConvertTo-Json {throw 'cannot serialize'}

        Format-ProjectJsonValue -Value $stub | Should -Be 'unserializable-fallback'
    }
}
