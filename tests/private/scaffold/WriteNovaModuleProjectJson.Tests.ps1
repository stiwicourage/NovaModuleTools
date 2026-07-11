BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    function Get-NovaScaffoldModuleVersion {
        $null
    }
    . (Join-Path $projectRoot 'src/private/scaffold/WriteNovaModuleProjectJson.ps1')
    function Get-NovaModuleProjectTemplatePath {param([switch]$Example) '/template/project.json'}
    function Read-ProjectJsonData {param($ProjectJsonPath) @{
        ProjectName='X'; Description='X desc'; Version='0.0.1'
        Manifest = @{Author='?'; PowerShellHostVersion='5.1'; GUID='00000000-0000-0000-0000-000000000000'}
        Pester = @{
            Enabled = $true
            CodeCoverage = @{
                Enabled = $true
                Path = @('src/public/*.ps1')
                CoveragePercentTarget = 90
            }
        }
    }}
    function Write-ProjectJsonData {param($ProjectJsonPath,$Data) $script:writtenPath=$ProjectJsonPath; $script:writtenData=$Data}
}

Describe 'Write-NovaModuleProjectJson' {
    BeforeEach {
        $script:writtenPath = $null
        $script:writtenData = $null
    }

    It 'writes resolved answers, regenerates GUID and removes Pester when not enabled' {
        $answer = @{ProjectName='Mod'; Description='desc'; Version='1.0.0'; Author='Me'; PowerShellHostVersion='7.4'; EnablePester='No'}
        Write-NovaModuleProjectJson -Answer $answer -ProjectJsonFile '/out/project.json'
        $script:writtenPath | Should -Be '/out/project.json'
        $script:writtenData.ProjectName | Should -Be 'Mod'
        $script:writtenData.Description | Should -Be 'desc'
        $script:writtenData.Manifest.Author | Should -Be 'Me'
        $script:writtenData.Manifest.PowerShellHostVersion | Should -Be '7.4'
        $script:writtenData.Manifest.GUID | Should -Not -Be '00000000-0000-0000-0000-000000000000'
        $script:writtenData.ContainsKey('Pester') | Should -BeFalse
    }

    It 'keeps Pester when EnablePester is Yes' {
        $answer = @{ProjectName='Mod'; Description='desc'; Version='1.0.0'; Author='Me'; PowerShellHostVersion='7.4'; EnablePester='Yes'}
        Write-NovaModuleProjectJson -Answer $answer -ProjectJsonFile '/out/project.json'
        $script:writtenData.ContainsKey('Pester') | Should -BeTrue
    }

    It 'preserves template GUID and Pester in example mode' {
        $answer = @{ProjectName='Mod'; Description='desc'; Version='1.0.0'; Author='Me'; PowerShellHostVersion='7.4'; EnablePester='No'}
        Write-NovaModuleProjectJson -Answer $answer -ProjectJsonFile '/out/project.json' -Example
        $script:writtenData.Manifest.GUID | Should -Be '00000000-0000-0000-0000-000000000000'
        $script:writtenData.ContainsKey('Pester') | Should -BeTrue
        $script:writtenData.Pester.CodeCoverage.Enabled | Should -BeTrue
    }

    It 'omits $schema when module version is not available (dot-sourced test context)' {
        $answer = @{ProjectName='Mod'; Description='desc'; Version='1.0.0'; Author='Me'; PowerShellHostVersion='7.4'; EnablePester='Yes'}
        Write-NovaModuleProjectJson -Answer $answer -ProjectJsonFile '/out/project.json'
        $script:writtenData.ContainsKey('$schema') | Should -BeFalse
    }

    It 'injects $schema with the correct URL when module version is available' {
        $root    = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
        $srcFile = Join-Path $root 'src/private/scaffold/WriteNovaModuleProjectJson.ps1'
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("NovaSchemaTest-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        try {
            $psm1 = Join-Path $tempDir 'NovaSchemaTestMod.psm1'
            $psd1 = Join-Path $tempDir 'NovaSchemaTestMod.psd1'

            Set-Content -LiteralPath $psm1 -Value @"
`$script:capturedData = `$null
function Get-NovaScaffoldModuleVersion { [version]'3.1.0' }
function Get-NovaModuleProjectTemplatePath { param([switch]`$Example) '/template/project.json' }
function Read-ProjectJsonData { param(`$ProjectJsonPath)
    @{ ProjectName='X'; Description='X'; Version='0.0.1'
       Manifest=@{Author='?'; PowerShellHostVersion='5.1'; GUID='00000000-0000-0000-0000-000000000000'}
       Pester=@{Enabled=`$true; CodeCoverage=@{Enabled=`$true; Path=@('src/public/*.ps1'); CoveragePercentTarget=90}} }
}
function Write-ProjectJsonData { param(`$ProjectJsonPath, `$Data) `$script:capturedData = `$Data }
. "$srcFile"
"@
            New-ModuleManifest -Path $psd1 -RootModule 'NovaSchemaTestMod.psm1' `
                -ModuleVersion '3.1.0' -FunctionsToExport @('Write-NovaModuleProjectJson') -Author 'Test'
            Import-Module $psd1 -Force -Global

            $answer = @{ProjectName='Mod'; Description='desc'; Version='1.0.0'; Author='Me';
                        PowerShellHostVersion='7.4'; EnablePester='Yes'}
            InModuleScope 'NovaSchemaTestMod' -Parameters @{Answer = $answer} {
                param($Answer)
                Write-NovaModuleProjectJson -Answer $Answer -ProjectJsonFile '/out/project.json'
            }

            $capturedData = & (Get-Module 'NovaSchemaTestMod') { $script:capturedData }
            $capturedData['$schema'] | Should -Be 'https://www.novamoduletools.com/schema/v3/project.json'
        } finally {
            Get-Module 'NovaSchemaTestMod' | Remove-Module -Force -ErrorAction SilentlyContinue
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
