BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/Get-ProjectPreamble.ps1')

    function Get-ProjectJsonValueTypeName {param($Value)}
    function Format-ProjectJsonValue {param($Value)}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'Get-ProjectPreamble' {
    It 'returns an empty array when Preamble is not configured' {
        $result = Get-ProjectPreamble -ProjectData @{}

        @($result).Count | Should -Be 0
    }

    It 'returns the configured preamble string array' {
        $result = Get-ProjectPreamble -ProjectData @{Preamble = @('a', 'b')}

        $result.Count | Should -Be 2
        $result[0] | Should -Be 'a'
        $result[1] | Should -Be 'b'
    }

    It 'throws when Preamble is not an array' {
        Mock Get-ProjectJsonValueTypeName {return 'String'}
        Mock Format-ProjectJsonValue {return '"x"'}

        {Get-ProjectPreamble -ProjectData @{Preamble = 'oops'}} | Should -Throw
    }

    It 'throws when a Preamble entry is not a string' {
        Mock Get-ProjectJsonValueTypeName {return 'Int32'}
        Mock Format-ProjectJsonValue {return '7'}

        {Get-ProjectPreamble -ProjectData @{Preamble = @('a', 7)}} | Should -Throw
    }
}
