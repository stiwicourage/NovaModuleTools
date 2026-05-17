BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/NewNovaErrorRecord.ps1')
}

Describe 'New-NovaErrorRecord' {
    It 'builds an ErrorRecord with the provided values' {
        $record = New-NovaErrorRecord -Message 'boom' -ErrorId 'Nova.Test.Boom' -Category InvalidData -TargetObject 'target'

        $record | Should -BeOfType [System.Management.Automation.ErrorRecord]
        $record.FullyQualifiedErrorId | Should -Be 'Nova.Test.Boom'
        $record.CategoryInfo.Category | Should -Be 'InvalidData'
        $record.TargetObject | Should -Be 'target'
        $record.Exception.Message | Should -Be 'boom'
    }

    It 'accepts a null TargetObject' {
        $record = New-NovaErrorRecord -Message 'm' -ErrorId 'id' -Category InvalidOperation -TargetObject $null

        $record.TargetObject | Should -BeNullOrEmpty
    }
}
