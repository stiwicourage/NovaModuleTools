BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/WriteNovaModuleProjectJson.ps1')
    function Get-NovaModuleProjectTemplatePath {param([switch]$Example) '/template/project.json'}
    function Read-ProjectJsonData {param($ProjectJsonPath) @{
        ProjectName='X'; Description='X desc'; Version='0.0.1'
        Manifest = @{Author='?'; PowerShellHostVersion='5.1'; GUID='00000000-0000-0000-0000-000000000000'}
        Pester = @{Enabled=$true}
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
    }
}
