BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleScaffoldPaths.ps1')
}

Describe 'Get-NovaModuleScaffoldLayout' {
    It 'composes scaffold paths under the provided base path and project name' {
        $layout = Get-NovaModuleScaffoldLayout -Path '/tmp/projects' -ProjectName 'DemoModule'

        $layout.Project | Should -Be (Join-Path '/tmp/projects' 'DemoModule')
        $layout.Src | Should -Be (Join-Path $layout.Project 'src')
        $layout.Private | Should -Be (Join-Path $layout.Src 'private')
        $layout.Public | Should -Be (Join-Path $layout.Src 'public')
        $layout.Resources | Should -Be (Join-Path $layout.Src 'resources')
        $layout.Classes | Should -Be (Join-Path $layout.Src 'classes')
        $layout.Tests | Should -Be (Join-Path $layout.Project 'tests')
        $layout.ProjectJsonFile | Should -Be (Join-Path $layout.Project 'project.json')
    }
}
