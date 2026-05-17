BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/ImportNovaPublishedLocalModule.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Import-NovaPublishedLocalModule' {
    It 'throws when the manifest path does not exist' {
        {Import-NovaPublishedLocalModule -ProjectName 'X' -ManifestPath '/does/not/exist.psd1'} | Should -Throw '*Expected locally published module manifest*'
    }
}
