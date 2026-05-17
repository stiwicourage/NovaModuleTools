BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetLocalModulePathEntryList.ps1')

    function Get-NovaEnvironmentVariableValue {param($Name) return $null}
}

Describe 'Get-LocalModulePathEntryList' {
    It 'returns an empty array when PSModulePath is empty' {
        Mock Get-NovaEnvironmentVariableValue {return ''}
        $result = Get-LocalModulePathEntryList
        @($result).Count | Should -Be 0
    }

    It 'splits, trims, and deduplicates path entries' {
        $sep = [IO.Path]::PathSeparator
        Mock Get-NovaEnvironmentVariableValue {return "/a$sep  /b  $sep/a$sep"}
        $result = Get-LocalModulePathEntryList
        @($result).Count | Should -Be 2
        $result | Should -Contain '/a'
        $result | Should -Contain '/b'
    }
}
