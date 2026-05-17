BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/AddProjectPreambleToModuleBuilder.ps1')
}

Describe 'Add-ProjectPreambleToModuleBuilder' {
    It 'appends each preamble line followed by a blank separator' {
        $builder = [System.Text.StringBuilder]::new()
        $projectInfo = [pscustomobject]@{Preamble = @('Set-StrictMode -Version Latest', '$ErrorActionPreference = ''Stop''')}

        Add-ProjectPreambleToModuleBuilder -Builder $builder -ProjectInfo $projectInfo

        $text = $builder.ToString()
        $text | Should -Match 'Set-StrictMode -Version Latest'
        $text | Should -Match 'ErrorActionPreference'
        ($text -split "`r?`n").Count | Should -BeGreaterOrEqual 4
    }

    It 'returns without writing when preamble is empty' {
        $builder = [System.Text.StringBuilder]::new()
        $projectInfo = [pscustomobject]@{Preamble = @()}

        Add-ProjectPreambleToModuleBuilder -Builder $builder -ProjectInfo $projectInfo

        $builder.Length | Should -Be 0
    }
}
