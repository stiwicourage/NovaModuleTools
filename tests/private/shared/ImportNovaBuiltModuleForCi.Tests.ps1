BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')

    function Get-NovaProjectInfo {param([string]$Path)}
}

Describe 'Resolve-NovaCiProjectInfo' {
    It 'returns the provided ProjectInfo without calling Get-NovaProjectInfo' {
        Mock Get-NovaProjectInfo {throw 'should not be called'}
        $info = [pscustomobject]@{ProjectName = 'X'; OutputModuleDir = '/d'}

        Resolve-NovaCiProjectInfo -ProjectInfo $info | Should -Be $info
    }

    It 'falls back to Get-NovaProjectInfo when ProjectInfo is null' {
        Mock Get-NovaProjectInfo {return [pscustomobject]@{ProjectName = 'Demo'; OutputModuleDir = '/d'}}

        $result = Resolve-NovaCiProjectInfo -ProjectRoot '/p' -ProjectInfo $null

        $result.ProjectName | Should -Be 'Demo'
    }
}

Describe 'Get-NovaBuiltModuleManifestPathForCi' {
    It 'returns the manifest path inside the output module directory' {
        $info = [pscustomobject]@{ProjectName = 'Demo'; OutputModuleDir = '/dist/Demo'}

        Get-NovaBuiltModuleManifestPathForCi -ProjectInfo $info | Should -Be (Join-Path '/dist/Demo' 'Demo.psd1')
    }
}

Describe 'Import-NovaBuiltModuleForCi' {
    It 'throws when the manifest does not exist' {
        Mock Get-NovaProjectInfo {return [pscustomobject]@{ProjectName = 'Demo'; OutputModuleDir = (Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N')))}}

        {Import-NovaBuiltModuleForCi -ProjectRoot '/p'} | Should -Throw
    }
}
