BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/CopyNovaExampleProjectTemplate.ps1')

    function Get-NovaModuleProjectTemplatePath {param([switch]$Example)}
}

Describe 'Copy-NovaExampleProjectTemplate' {
    BeforeAll {
        $script:templateRoot = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().Guid))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:templateRoot 'src')
        Set-Content -LiteralPath (Join-Path $script:templateRoot 'project.json') -Value '{}' -NoNewline
        Set-Content -LiteralPath (Join-Path $script:templateRoot 'src/example.ps1') -Value '# example' -NoNewline

        $script:destination = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().Guid))
    }

    AfterAll {
        Remove-Item -LiteralPath $script:templateRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:destination -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'copies every template item under the resolved template root into the destination' {
        Mock Get-NovaModuleProjectTemplatePath {return (Join-Path $script:templateRoot 'project.json')}

        Copy-NovaExampleProjectTemplate -DestinationPath $script:destination.FullName

        Test-Path -LiteralPath (Join-Path $script:destination 'project.json') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $script:destination 'src/example.ps1') | Should -BeTrue
        Assert-MockCalled Get-NovaModuleProjectTemplatePath -Times 1 -ParameterFilter {$Example.IsPresent}
    }
}
