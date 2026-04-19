BeforeAll {
    $data = Get-NovaProjectInfo
}

Describe 'General Module Control' {
    It 'Should import without errors' {
        {Import-Module -Name $data.OutputModuleDir -ErrorAction Stop} | Should -Not -Throw
        Get-Module -Name $data.ProjectName | Should -Not -BeNullOrEmpty
    }

    It 'Imports the renamed public commands without the old unapproved-verb warning' {
        Remove-Module -Name $data.ProjectName -ErrorAction SilentlyContinue

        $importOutput = @(Import-Module -Name $data.OutputModuleDir -Force -Verbose 4>&1)
        $importText = $importOutput -join [Environment]::NewLine

        $importText | Should -Not -Match 'include unapproved verbs'
        Get-Command -Name New-NovaModulePackage -Module $data.ProjectName -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command -Name Deploy-NovaPackage -Module $data.ProjectName -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command -Name Initialize-NovaModule -Module $data.ProjectName -ErrorAction Stop | Should -Not -BeNullOrEmpty
        {Get-Command -Name Pack-NovaModule -Module $data.ProjectName -ErrorAction Stop} | Should -Throw
        {Get-Command -Name Merge-NovaModule -Module $data.ProjectName -ErrorAction Stop} | Should -Throw
        {Get-Command -Name Upload-NovaPackage -Module $data.ProjectName -ErrorAction Stop} | Should -Throw
        {Get-Command -Name New-NovaModule -Module $data.ProjectName -ErrorAction Stop} | Should -Throw
    }
}
