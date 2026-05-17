BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterTestResultPath.ps1')
}

Describe 'Get-NovaPesterTestResultPath' {
    It 'returns the artifacts/TestResults.xml path under the project root' {
        Get-NovaPesterTestResultPath -ProjectRoot '/p' | Should -Be ([System.IO.Path]::Join('/p', 'artifacts', 'TestResults.xml'))
    }
}
