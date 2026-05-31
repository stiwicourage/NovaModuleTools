BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/CopyNovaExampleProjectTemplate.ps1')

    function Get-NovaModuleProjectTemplatePath {param([switch]$Example)}
}

Describe 'Copy-NovaExampleProjectTemplate' {
    BeforeAll {
        $script:templateRoot = New-Item -ItemType Directory -Path (Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().Guid))
        $null = New-Item -ItemType Directory -Path (Join-Path $script:templateRoot 'src')
        $null = New-Item -ItemType Directory -Path (Join-Path $script:templateRoot 'tests/public') -Force
        Set-Content -LiteralPath (Join-Path $script:templateRoot 'project.json') -Value '{}' -NoNewline
        Set-Content -LiteralPath (Join-Path $script:templateRoot 'src/example.ps1') -Value '# example' -NoNewline
        Set-Content -LiteralPath (Join-Path $script:templateRoot 'tests/public/example.tests.ps1') -Value '# test' -NoNewline

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
        Test-Path -LiteralPath (Join-Path $script:destination 'tests/public/example.tests.ps1') | Should -BeTrue
        Assert-MockCalled Get-NovaModuleProjectTemplatePath -Times 1 -ParameterFilter {$Example.IsPresent}
    }

    It 'copies the packaged example template with source-mirrored tests and enabled coverage defaults' {
        $destination = New-Item -ItemType Directory -Path (Join-Path $TestDrive 'PackagedExample')
        Mock Get-NovaModuleProjectTemplatePath {return (Join-Path $projectRoot 'src/resources/example/project.json')}

        Copy-NovaExampleProjectTemplate -DestinationPath $destination.FullName

        $projectJson = Get-Content -LiteralPath (Join-Path $destination 'project.json') -Raw | ConvertFrom-Json -AsHashtable

        $projectJson.Pester.CodeCoverage.Enabled | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $destination 'tests/public/Get-ExampleGreeting.Tests.ps1') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $destination 'tests/public/Get-ExampleGreeting.Integration.Tests.ps1') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $destination 'tests/private/Get-ExampleConfiguration.Tests.ps1') | Should -BeTrue
    }
}
