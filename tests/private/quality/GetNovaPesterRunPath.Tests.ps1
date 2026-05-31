BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterRunPath.ps1')
}

Describe 'Get-NovaPesterRunPath' {
    It 'returns matching recursive test files when BuildRecursiveFolders is enabled' {
        $testsDir = Join-Path $TestDrive 'tests-recursive'
        $nestedDir = Join-Path $testsDir 'private/quality'
        New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null

        $topLevelPath = Join-Path $testsDir 'TopLevel.Tests.ps1'
        $nestedPath = Join-Path $nestedDir 'Nested.Tests.ps1'
        Set-Content -LiteralPath $topLevelPath -Value '# test'
        Set-Content -LiteralPath $nestedPath -Value '# test'

        $info = [pscustomobject]@{BuildRecursiveFolders = $true; TestsDir = $testsDir}
        $expectedPath = @($nestedPath, $topLevelPath) | Sort-Object
        Get-NovaPesterRunPath -ProjectInfo $info | Should -Be $expectedPath
    }

    It 'returns only top-level matching files when BuildRecursiveFolders is disabled' {
        $testsDir = Join-Path $TestDrive 'tests-flat'
        $nestedDir = Join-Path $testsDir 'private'
        New-Item -ItemType Directory -Path $nestedDir -Force | Out-Null

        $topLevelPath = Join-Path $testsDir 'TopLevel.Tests.ps1'
        $nestedPath = Join-Path $nestedDir 'Nested.Tests.ps1'
        Set-Content -LiteralPath $topLevelPath -Value '# test'
        Set-Content -LiteralPath $nestedPath -Value '# test'

        $info = [pscustomobject]@{BuildRecursiveFolders = $false; TestsDir = $testsDir}
        Get-NovaPesterRunPath -ProjectInfo $info | Should -Be @($topLevelPath)
    }

    It 'excludes integration tests when an exclude pattern is provided' {
        $testsDir = Join-Path $TestDrive 'tests-filtered'
        New-Item -ItemType Directory -Path $testsDir -Force | Out-Null

        $unitPath = Join-Path $testsDir 'Alpha.Tests.ps1'
        $integrationPath = Join-Path $testsDir 'Alpha.Integration.Tests.ps1'
        Set-Content -LiteralPath $unitPath -Value '# unit'
        Set-Content -LiteralPath $integrationPath -Value '# integration'

        $info = [pscustomobject]@{BuildRecursiveFolders = $false; TestsDir = $testsDir}
        Get-NovaPesterRunPath -ProjectInfo $info -IncludePattern '*.Tests.ps1' -ExcludePattern '*.Integration.Tests.ps1' | Should -Be @($unitPath)
    }
}
