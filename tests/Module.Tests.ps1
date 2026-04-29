BeforeAll {
    $data = Get-NovaProjectInfo
    $script:repoRoot = Split-Path -Parent $PSScriptRoot
}

Describe 'General Module Control' {
    It 'Should import without errors' {
        {Import-Module -Name $data.OutputModuleDir -ErrorAction Stop} | Should -Not -Throw
        Get-Module -Name $data.ProjectName | Should -Not -BeNullOrEmpty
    }

    It 'Imports the renamed public commands without the old unapproved-verb warning' {
        Get-Module -Name $data.ProjectName -All | Remove-Module -Force -ErrorAction SilentlyContinue

        $module = Import-Module -Name $data.OutputModuleDir -Force -PassThru
        $importOutput = @(Import-Module -Name $data.OutputModuleDir -Force -Verbose 4>&1)
        $importText = $importOutput -join [Environment]::NewLine
        $exportedCommandNameList = $module.ExportedCommands.Keys

        $importText | Should -Not -Match 'include unapproved verbs'
        $exportedCommandNameList | Should -Contain 'New-NovaModulePackage'
        $exportedCommandNameList | Should -Contain 'Deploy-NovaPackage'
        $exportedCommandNameList | Should -Contain 'Initialize-NovaModule'
        $exportedCommandNameList | Should -Not -Contain 'Pack-NovaModule'
        $exportedCommandNameList | Should -Not -Contain 'Merge-NovaModule'
        $exportedCommandNameList | Should -Not -Contain 'Upload-NovaPackage'
        $exportedCommandNameList | Should -Not -Contain 'New-NovaModule'
    }

    It 'Freshly importing the built module can run Update-NovaModuleVersion -WhatIf without missing private helpers' {
        Get-Module -Name $data.ProjectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
        Import-Module -Name $data.OutputModuleDir -Force | Out-Null

        $result = Update-NovaModuleVersion -Path $script:repoRoot -WhatIf

        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'PreviousVersion'
        $result.PSObject.Properties.Name | Should -Contain 'NewVersion'
        $result.PSObject.Properties.Name | Should -Contain 'Label'
        $result.PSObject.Properties.Name | Should -Contain 'CommitCount'
    }

    It 'Import-BuiltCiModule.ps1 loads the built module into the caller session for subsequent commands' {
        $helperPath = Join-Path $script:repoRoot 'scripts/build/ci/Import-BuiltCiModule.ps1'
        Get-Module -Name $data.ProjectName -All | Remove-Module -Force -ErrorAction SilentlyContinue

        & $helperPath | Out-Null

        $importedModule = Get-Module -Name $data.ProjectName -ErrorAction Stop
        (Split-Path -Parent $importedModule.Path) | Should -Be $data.OutputModuleDir

        $result = Update-NovaModuleVersion -Path $script:repoRoot -WhatIf

        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'NewVersion'
    }
}
