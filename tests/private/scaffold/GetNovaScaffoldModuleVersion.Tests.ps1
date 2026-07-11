BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaScaffoldModuleVersion.ps1')
}

Describe 'Get-NovaScaffoldModuleVersion' {
    It 'returns null when dot-sourced outside a module context' {
        $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        $sourcePath = Join-Path $projectRoot 'src/private/scaffold/GetNovaScaffoldModuleVersion.ps1'
        $powershell = [powershell]::Create()

        try {
            $null = $powershell.AddScript(". '$sourcePath'; Get-NovaScaffoldModuleVersion")
            @($powershell.Invoke())[0] | Should -BeNullOrEmpty
        } finally {
            $powershell.Dispose()
        }
    }

    It 'returns the module version when invoked inside a module context' {
        $root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        $srcFile = Join-Path $root 'src/private/scaffold/GetNovaScaffoldModuleVersion.ps1'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaScaffoldVersion-$([guid]::NewGuid() )")
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

        try {
            $psm1 = Join-Path $tempDir 'NovaScaffoldVersionTestMod.psm1'
            $psd1 = Join-Path $tempDir 'NovaScaffoldVersionTestMod.psd1'
            Set-Content -LiteralPath $psm1 -Value ". `"$srcFile`""
            New-ModuleManifest -Path $psd1 -RootModule 'NovaScaffoldVersionTestMod.psm1' `
                -ModuleVersion '3.1.0' -FunctionsToExport @('Get-NovaScaffoldModuleVersion') -Author 'Test'
            Import-Module $psd1 -Force -Global

            $version = InModuleScope 'NovaScaffoldVersionTestMod' {
                Get-NovaScaffoldModuleVersion
            }

            $version | Should -Be ([version]'3.1.0')
        } finally {
            Get-Module 'NovaScaffoldVersionTestMod' | Remove-Module -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}



