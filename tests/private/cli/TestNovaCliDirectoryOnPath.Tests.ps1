BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/TestNovaCliDirectoryOnPath.ps1')

    function Get-NovaEnvironmentVariableValue {param([string]$Name) return $null}
}

Describe 'Test-NovaCliDirectoryOnPath' {
    It 'returns true when the directory matches a PATH entry' {
        $dir = [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        Mock Get-NovaEnvironmentVariableValue {return "$dir$([System.IO.Path]::PathSeparator)/usr/bin"}
        Test-NovaCliDirectoryOnPath -Directory $dir | Should -BeTrue
    }

    It 'returns false when the directory is not on PATH' {
        Mock Get-NovaEnvironmentVariableValue {return '/usr/bin'}
        Test-NovaCliDirectoryOnPath -Directory ([System.IO.Path]::GetTempPath()) | Should -BeFalse
    }
}
