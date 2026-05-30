BeforeAll {
    . (Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'src/private/build/ExportNovaProjectJsonSchema.ps1')
}

Describe 'Export-NovaProjectJsonSchema' {
    BeforeAll {
        function Get-NovaProjectInfo { [pscustomobject]@{ Version = '3.1.0' } }
        function Get-ResourceFilePath { param([string]$FileName) Join-Path $TestDrive 'Schema-Project.json' }
    }

    BeforeEach {
        Set-Content -Path (Join-Path $TestDrive 'Schema-Project.json') -Value '{"type":"object"}'
    }

    It 'copies Schema-Project.json to docs/schema/v{major}/ derived from project version' {
        $outputDir = Join-Path $TestDrive 'docs/schema/v3'
        Push-Location $TestDrive
        try {
            Export-NovaProjectJsonSchema
            Test-Path (Join-Path $outputDir 'project.json') | Should -BeTrue
        } finally {
            Pop-Location
        }
    }

    It 'creates the output directory when it does not exist' {
        Push-Location $TestDrive
        try {
            $outputDir = Join-Path $TestDrive 'docs/schema/v3'
            if (Test-Path $outputDir) { Remove-Item $outputDir -Recurse -Force }
            Export-NovaProjectJsonSchema
            Test-Path $outputDir | Should -BeTrue
        } finally {
            Pop-Location
        }
    }
}
