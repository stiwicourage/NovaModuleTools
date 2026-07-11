BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleProjectTemplatePath.ps1')

    function Get-ResourceFilePath {param([string]$FileName) return "/resources/$FileName"}
}

Describe 'Get-NovaModuleProjectTemplatePath' {
    It 'resolves the standard template path through Get-ResourceFilePath' {
        Mock Get-ResourceFilePath {return "/resources/$FileName"}

        $path = Get-NovaModuleProjectTemplatePath

        $path | Should -Be '/resources/ProjectTemplate.json'
        Should -Invoke Get-ResourceFilePath -Times 1 -ParameterFilter {
            $FileName -eq 'ProjectTemplate.json'
        }
    }

    It 'resolves the example template path under example/project.json when -Example is set' {
        Mock Get-ResourceFilePath {return "/resources/$FileName"}

        $path = Get-NovaModuleProjectTemplatePath -Example

        $path | Should -Match 'example.+project\.json$'
        Should -Invoke Get-ResourceFilePath -Times 1 -ParameterFilter {
            $FileName -like 'example*project.json'
        }
    }
}
