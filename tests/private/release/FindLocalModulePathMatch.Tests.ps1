BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/FindLocalModulePathMatch.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Find-LocalModulePathMatch' {
    It 'returns the first existing path matching the pattern' {
        $tmp = [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar)
        $details = [pscustomobject]@{Message='m'; ErrorId='e'; Category=[System.Management.Automation.ErrorCategory]::ObjectNotFound; TargetObject='t'}
        Find-LocalModulePathMatch -ModulePaths @($tmp) -MatchPattern '.*' -ErrorDetails $details | Should -Be $tmp
    }

    It 'throws when no entry matches the pattern' {
        $details = [pscustomobject]@{Message='not found'; ErrorId='e'; Category=[System.Management.Automation.ErrorCategory]::ObjectNotFound; TargetObject='t'}
        {Find-LocalModulePathMatch -ModulePaths @('/a') -MatchPattern '^nope$' -ErrorDetails $details} | Should -Throw '*not found*'
    }

    It 'throws when the matched entry does not exist on disk' {
        $details = [pscustomobject]@{Message='missing'; ErrorId='e'; Category=[System.Management.Automation.ErrorCategory]::ObjectNotFound; TargetObject='t'}
        {Find-LocalModulePathMatch -ModulePaths @('/does/not/exist/abc') -MatchPattern '.*' -ErrorDetails $details} | Should -Throw '*missing*'
    }
}
