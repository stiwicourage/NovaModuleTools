BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomeChoiceOptionList.ps1')
}

Describe 'Get-AwesomeChoiceOptionList' {
    It 'returns ChoiceDescription items with prefixed labels' {
        $choice = [ordered]@{Yes = 'pick yes'; No = 'pick no'}
        $result = Get-AwesomeChoiceOptionList -Choice $choice
        $result.Count | Should -Be 2
        $result[0].Label | Should -Be '&Yes'
        $result[0].HelpMessage | Should -Be 'pick yes'
        $result[1].Label | Should -Be '&No'
    }
}
