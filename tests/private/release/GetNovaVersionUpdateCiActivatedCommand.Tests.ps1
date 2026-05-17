BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionUpdateCiActivatedCommand.ps1')

    function Get-NovaProjectInfo {param($Path) return [pscustomobject]@{ProjectName='X'; OutputModuleDir='/dist/X'}}
    function Import-NovaBuiltModuleForCi {param($ProjectInfo) return [pscustomobject]@{ExportedCommands=@{'Update-NovaModuleVersion'='imported'}}}
}

Describe 'Get-NovaVersionUpdateCiActivatedCommand' {
    It 'returns $null when the current command is already from the built module' {
        $builtModulePath = Join-Path '/dist/X' 'X.psm1'
        $fakeCommand = [pscustomobject]@{ScriptBlock = [pscustomobject]@{Module = [pscustomobject]@{Path = $builtModulePath}}}
        Mock Get-Command {return $fakeCommand}
        Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot '/proj' | Should -BeNullOrEmpty
    }

    It 'imports the built module and returns its exported command when paths differ' {
        $fakeCommand = [pscustomobject]@{ScriptBlock = [pscustomobject]@{Module = [pscustomobject]@{Path = '/other/path.psm1'}}}
        Mock Get-Command {return $fakeCommand}
        Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot '/proj' | Should -Be 'imported'
    }
}
