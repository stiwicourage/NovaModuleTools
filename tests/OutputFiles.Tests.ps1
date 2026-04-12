$script:outputFileProjectInfo = Get-NovaProjectInfo
$script:outputFileList = @(Get-ChildItem $script:outputFileProjectInfo.OutputModuleDir -File)

Describe 'Module and Manifest testing' {
    Context 'Test <_.Name>' -ForEach $script:outputFileList {
        It 'is valid PowerShell Code' {
            $psFile = Get-Content -Path $_ -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
}