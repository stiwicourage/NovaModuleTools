BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/AddNovaCliOptionValue.ps1')
}

Describe 'Add-NovaCliOptionValue' {
    It 'creates a single-entry array when the option is new' {
        $options = @{}
        Add-NovaCliOptionValue -Options $options -Name 'PackagePath' -Value 'a'
        ,$options.PackagePath | Should -BeOfType ([System.Array])
        $options.PackagePath.Count | Should -Be 1
        $options.PackagePath[0] | Should -Be 'a'
    }

    It 'appends additional values into the existing option array' {
        $options = @{PackagePath = 'a'}
        Add-NovaCliOptionValue -Options $options -Name 'PackagePath' -Value 'b'
        $options.PackagePath.Count | Should -Be 2
        $options.PackagePath[1] | Should -Be 'b'
    }
}
