BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetLocalModulePath.ps1')

    function Get-LocalModulePathEntryList {return @('/a')}
    function Get-LocalModulePathPattern {return 'pattern'}
    function Get-LocalModulePathErrorMessage {param($MatchPattern) return "no $MatchPattern"}
    function Find-LocalModulePathMatch {param($ModulePaths, $MatchPattern, $ErrorDetails) return "match-of-$MatchPattern"}
}

Describe 'Get-LocalModulePath' {
    It 'delegates to Find-LocalModulePathMatch with the assembled error details' {
        Mock Find-LocalModulePathMatch {return "ok-$($ErrorDetails.ErrorId)"}
        Get-LocalModulePath | Should -Be 'ok-Nova.Environment.LocalModulePathNotFound'
    }
}
