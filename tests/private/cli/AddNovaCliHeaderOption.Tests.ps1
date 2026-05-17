BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/AddNovaCliHeaderOption.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Add-NovaCliHeaderOption' {
    It 'parses Name=Value into the Headers map' {
        $options = @{}
        Add-NovaCliHeaderOption -Options $options -HeaderArgument 'X-Trace=abc'
        $options.Headers['X-Trace'] | Should -Be 'abc'
    }

    It 'preserves values that contain "=" after the first separator' {
        $options = @{}
        Add-NovaCliHeaderOption -Options $options -HeaderArgument 'X-Token=a=b=c'
        $options.Headers['X-Token'] | Should -Be 'a=b=c'
    }

    It 'rejects header arguments without a name part' {
        {Add-NovaCliHeaderOption -Options @{} -HeaderArgument '=value'} | Should -Throw '*Invalid header argument*'
    }

    It 'rejects header arguments without a separator' {
        {Add-NovaCliHeaderOption -Options @{} -HeaderArgument 'noseparator'} | Should -Throw '*Invalid header argument*'
    }
}
