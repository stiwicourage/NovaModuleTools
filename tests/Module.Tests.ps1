BeforeAll {
    $data = Get-NovaProjectInfo
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
}
