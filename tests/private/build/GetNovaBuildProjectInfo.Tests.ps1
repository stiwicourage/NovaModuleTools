BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/GetNovaBuildProjectInfo.ps1')

    function Get-NovaProjectInfo {param([string]$Path)}
}

Describe 'Get-NovaBuildProjectInfo' {
    It 'returns the provided ProjectInfo unchanged' {
        $info = [pscustomobject]@{ProjectRoot = '/tmp'}

        Get-NovaBuildProjectInfo -ProjectInfo $info | Should -Be $info
    }

    It 'falls back to Get-NovaProjectInfo when ProjectInfo is null' {
        Mock Get-NovaProjectInfo {return [pscustomobject]@{ProjectRoot = '/from-fallback'}}

        $result = Get-NovaBuildProjectInfo -ProjectInfo $null

        $result.ProjectRoot | Should -Be '/from-fallback'
        Assert-MockCalled Get-NovaProjectInfo -Times 1
    }
}
