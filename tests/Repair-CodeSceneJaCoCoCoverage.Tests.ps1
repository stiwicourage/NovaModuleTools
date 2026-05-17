BeforeAll {
    $script:repairCoverageScriptPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'Repair-CodeSceneJaCoCoCoverage.ps1')).Path

    function Invoke-RepairCodeSceneJaCoCoCoverageTestScript {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)][string]$RunnerContent
        )

        $runnerPath = Join-Path $TestDrive 'Run-RepairCodeSceneJaCoCoCoverage.ps1'
        $content = @"
$RunnerContent

if (`$null -ne `$LASTEXITCODE) {
    exit `$LASTEXITCODE
}

if (`$?) {
    exit 0
}

exit 1
"@
        Set-Content -LiteralPath $runnerPath -Value $content -Encoding utf8

        $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = @($output)
        }
    }
}

Describe 'Repair-CodeSceneJaCoCoCoverage' {
    It 'normalizes class and sourcefile names to bare filenames' {
        $coveragePath = Join-Path $TestDrive 'coverage.xml'
        Set-Content -LiteralPath $coveragePath -Encoding utf8 -Value @'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<report name="Pester">
  <package name="src/private/build">
    <class name="src/private/build/Foo" sourcefilename="private/build/Foo.ps1" />
    <sourcefile name="private/build/Foo.ps1" />
  </package>
</report>
'@

        $runnerContent = "& '$script:repairCoverageScriptPath' -Path '$coveragePath'"
        $result = Invoke-RepairCodeSceneJaCoCoCoverageTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        [xml]$rewritten = Get-Content -LiteralPath $coveragePath -Raw
        $rewritten.SelectSingleNode('//class[@sourcefilename]').GetAttribute('sourcefilename') | Should -Be 'Foo.ps1'
        $rewritten.SelectSingleNode('//sourcefile[@name]').GetAttribute('name') | Should -Be 'Foo.ps1'
    }

    It 'leaves already normalized filenames unchanged' {
        $coveragePath = Join-Path $TestDrive 'coverage-already-normalized.xml'
        Set-Content -LiteralPath $coveragePath -Encoding utf8 -Value @'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<report name="Pester">
  <package name="src/private/build">
    <class name="src/private/build/Foo" sourcefilename="Foo.ps1" />
    <sourcefile name="Foo.ps1" />
  </package>
</report>
'@

        $runnerContent = "& '$script:repairCoverageScriptPath' -Path '$coveragePath'"
        $result = Invoke-RepairCodeSceneJaCoCoCoverageTestScript -RunnerContent $runnerContent

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        [xml]$rewritten = Get-Content -LiteralPath $coveragePath -Raw
        $rewritten.SelectSingleNode('//class[@sourcefilename]').GetAttribute('sourcefilename') | Should -Be 'Foo.ps1'
        $rewritten.SelectSingleNode('//sourcefile[@name]').GetAttribute('name') | Should -Be 'Foo.ps1'
    }
}
