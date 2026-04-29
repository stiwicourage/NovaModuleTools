BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'CodeSceneCoverageMap.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'CodeSceneCoverageXml.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'CoverageLowReport.ps1')

    foreach ($functionName in @(
        'ConvertTo-CoberturaRelativePath'
        'Get-CodeSceneCoverageErrorRecord'
        'Get-SourceSectionListFromBuiltModule'
        'Find-SourceSectionForLine'
        'Get-EmptyCoberturaLineBucket'
        'Add-CoberturaLineHit'
        'Get-CoberturaLineStat'
        'Get-CoberturaPackageName'
        'Get-CoberturaSourceLineRange'
        'Test-CoberturaLineOutsideSourceRange'
        'Add-CoberturaMappedLineHit'
        'Add-CoberturaLineNodeHit'
        'Get-CoberturaLineBucketMap'
        'Add-CoberturaAttribute'
        'Get-CoberturaClassElement'
        'Get-CoberturaPackageElement'
        'Get-CoberturaCoverageAttributeMap'
        'Get-CoberturaCoverageDocument'
        'Convert-CoberturaCoverageToSourcePath'
        'ConvertTo-CoverageLineRate'
        'Get-CoverageLowReportEntryList'
        'Format-CoverageLowReportLine'
        'Write-CoverageLowReport'
    )) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    $here = Split-Path -Parent $PSCommandPath
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'CodeScene Cobertura remapping helpers' {
    It 'remaps built-module coverage lines back to source files' {
        $repoRoot = Join-Path $TestDrive 'repo'
        $sourcePublicDir = Join-Path $repoRoot 'src/public'
        $sourcePrivateDir = Join-Path $repoRoot 'src/private'
        $buildDir = Join-Path $repoRoot 'dist/NovaModuleTools'
        $coveragePath = Join-Path $repoRoot 'artifacts/pester-coverage.cobertura.xml'
        $builtModulePath = Join-Path $buildDir 'NovaModuleTools.psm1'

        New-Item -ItemType Directory -Path $sourcePublicDir, $sourcePrivateDir, (Split-Path -Parent $coveragePath), $buildDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sourcePublicDir 'Invoke-Foo.ps1') -Encoding utf8 -Value @(
            'function Invoke-Foo {'
            "    'foo'"
            '}'
        )
        Set-Content -LiteralPath (Join-Path $sourcePrivateDir 'Invoke-Bar.ps1') -Encoding utf8 -Value @(
            'function Invoke-Bar {'
            "    'bar'"
            '}'
        )
        Set-Content -LiteralPath $builtModulePath -Encoding utf8 -Value @(
            '# Source: src/public/Invoke-Foo.ps1'
            'function Invoke-Foo {'
            "    'foo'"
            '}'
            ''
            '# Source: src/private/Invoke-Bar.ps1'
            'function Invoke-Bar {'
            "    'bar'"
            '}'
        )

        @'
<?xml version="1.0" encoding="utf-8"?>
<coverage lines-covered="4" lines-valid="4" line-rate="1" branches-covered="0" branches-valid="0" branch-rate="1" timestamp="1" version="1.0">
  <packages>
    <package name="dist/NovaModuleTools" line-rate="1" branch-rate="1">
      <classes>
        <class name="NovaModuleTools.psm1" filename="dist/NovaModuleTools/NovaModuleTools.psm1" line-rate="1" branch-rate="1">
          <methods />
          <lines>
            <line number="2" hits="1" />
            <line number="3" hits="1" />
            <line number="7" hits="1" />
            <line number="8" hits="0" />
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@ | Set-Content -LiteralPath $coveragePath -Encoding utf8

        Convert-CoberturaCoverageToSourcePath -CoveragePath $coveragePath -BuiltModulePath $builtModulePath -RepoRoot $repoRoot

        [xml]$convertedCoverage = Get-Content -LiteralPath $coveragePath -Raw
        $classNodes = @($convertedCoverage.SelectNodes('/coverage/packages/package/classes/class'))
        $classNodes.filename | Should -Contain 'src/public/Invoke-Foo.ps1'
        $classNodes.filename | Should -Contain 'src/private/Invoke-Bar.ps1'

        $fooClass = $classNodes | Where-Object filename -eq 'src/public/Invoke-Foo.ps1' | Select-Object -First 1
        $barClass = $classNodes | Where-Object filename -eq 'src/private/Invoke-Bar.ps1' | Select-Object -First 1

        @($fooClass.lines.line | ForEach-Object number) | Should -Be @(1, 2)
        @($fooClass.lines.line | ForEach-Object hits) | Should -Be @('1', '1')
        @($barClass.lines.line | ForEach-Object number) | Should -Be @(1, 2)
        @($barClass.lines.line | ForEach-Object hits) | Should -Be @('1', '0')
    }

    It 'fails clearly when the built module does not contain source markers' {
        $repoRoot = Join-Path $TestDrive 'repo-no-markers'
        $buildDir = Join-Path $repoRoot 'dist/NovaModuleTools'
        $coveragePath = Join-Path $repoRoot 'artifacts/pester-coverage.cobertura.xml'
        $builtModulePath = Join-Path $buildDir 'NovaModuleTools.psm1'

        New-Item -ItemType Directory -Path $buildDir, (Split-Path -Parent $coveragePath) -Force | Out-Null
        Set-Content -LiteralPath $builtModulePath -Encoding utf8 -Value 'function Invoke-Foo { }'
        @'
<?xml version="1.0" encoding="utf-8"?>
<coverage lines-covered="1" lines-valid="1" line-rate="1" branches-covered="0" branches-valid="0" branch-rate="1" timestamp="1" version="1.0">
  <packages>
    <package name="dist/NovaModuleTools" line-rate="1" branch-rate="1">
      <classes>
        <class name="NovaModuleTools.psm1" filename="dist/NovaModuleTools/NovaModuleTools.psm1" line-rate="1" branch-rate="1">
          <methods />
          <lines>
            <line number="1" hits="1" />
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@ | Set-Content -LiteralPath $coveragePath -Encoding utf8

        $thrown = $null
        try {
            Convert-CoberturaCoverageToSourcePath -CoveragePath $coveragePath -BuiltModulePath $builtModulePath -RepoRoot $repoRoot
        }
        catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.Exception.Message | Should -Be "Could not find any '# Source:' markers in built module: $builtModulePath"
        $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Coverage.BuiltModuleSourceMarkersMissing'
        $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ObjectNotFound)
        $thrown.TargetObject | Should -Be $builtModulePath
    }

    It 'ignores covered built-module preamble lines before the first source marker' {
        $repoRoot = Join-Path $TestDrive 'repo-with-preamble'
        $sourcePublicDir = Join-Path $repoRoot 'src/public'
        $buildDir = Join-Path $repoRoot 'dist/NovaModuleTools'
        $coveragePath = Join-Path $repoRoot 'artifacts/pester-coverage.cobertura.xml'
        $builtModulePath = Join-Path $buildDir 'NovaModuleTools.psm1'

        New-Item -ItemType Directory -Path $sourcePublicDir, (Split-Path -Parent $coveragePath), $buildDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $sourcePublicDir 'Invoke-Foo.ps1') -Encoding utf8 -Value @(
            'function Invoke-Foo {'
            "    'foo'"
            '}'
        )
        Set-Content -LiteralPath $builtModulePath -Encoding utf8 -Value @(
            'Set-StrictMode -Version Latest'
            "`$ErrorActionPreference = 'Stop'"
            ''
            '# Source: src/public/Invoke-Foo.ps1'
            'function Invoke-Foo {'
            "    'foo'"
            '}'
        )

        @'
<?xml version="1.0" encoding="utf-8"?>
<coverage lines-covered="4" lines-valid="4" line-rate="1" branches-covered="0" branches-valid="0" branch-rate="1" timestamp="1" version="1.0">
  <packages>
    <package name="dist/NovaModuleTools" line-rate="1" branch-rate="1">
      <classes>
        <class name="NovaModuleTools.psm1" filename="dist/NovaModuleTools/NovaModuleTools.psm1" line-rate="1" branch-rate="1">
          <methods />
          <lines>
            <line number="1" hits="1" />
            <line number="2" hits="1" />
            <line number="5" hits="1" />
            <line number="6" hits="1" />
          </lines>
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@ | Set-Content -LiteralPath $coveragePath -Encoding utf8

        Convert-CoberturaCoverageToSourcePath -CoveragePath $coveragePath -BuiltModulePath $builtModulePath -RepoRoot $repoRoot

        [xml]$convertedCoverage = Get-Content -LiteralPath $coveragePath -Raw
        $classNode = $convertedCoverage.SelectSingleNode('/coverage/packages/package/classes/class')

        $classNode.filename | Should -Be 'src/public/Invoke-Foo.ps1'
        @($classNode.lines.line | ForEach-Object number) | Should -Be @(1, 2)
        @($classNode.lines.line | ForEach-Object hits) | Should -Be @('1', '1')
    }

    It 'writes a low-coverage report sorted by line rate from Cobertura classes' {
        $coveragePath = Join-Path $TestDrive 'coverage.cobertura.xml'
        $reportPath = Join-Path $TestDrive 'coverage-low.txt'

        @'
<?xml version="1.0" encoding="utf-8"?>
<coverage lines-covered="6" lines-valid="8" line-rate="0.75" branches-covered="0" branches-valid="0" branch-rate="1" timestamp="1" version="1.0">
  <packages>
    <package name="src/private" line-rate="0.4375" branch-rate="1">
      <classes>
        <class name="Low.ps1" filename="src/private/Low.ps1" line-rate="0.125" branch-rate="1">
          <methods />
          <lines />
        </class>
        <class name="Mid.ps1" filename="src/private/Mid.ps1" line-rate="0.75" branch-rate="1">
          <methods />
          <lines />
        </class>
        <class name="High.ps1" filename="src/private/High.ps1" line-rate="1" branch-rate="1">
          <methods />
          <lines />
        </class>
      </classes>
    </package>
  </packages>
</coverage>
'@ | Set-Content -LiteralPath $coveragePath -Encoding utf8

        Write-CoverageLowReport -CoveragePath $coveragePath -OutputPath $reportPath

        @(Get-Content -LiteralPath $reportPath) | Should -Be @(
            '0.125000 src/private/Low.ps1',
            '0.750000 src/private/Mid.ps1'
        )
    }
}

Describe 'Coverage gaps for quality helpers' {
    It 'Write-NovaPesterTestResultReport writes a success NUnit-style report with default suite name' {
        $outputPath = Join-Path $TestDrive 'success-report.xml'

        InModuleScope $script:moduleName -Parameters @{OutputPath = $outputPath} {
            param($OutputPath)

            $testResult = [pscustomobject]@{
                Tests = @(
                    [pscustomobject]@{Result = 'Passed'}
                    [pscustomobject]@{Result = 'Passed'}
                    [pscustomobject]@{Result = 'Skipped'}
                    [pscustomobject]@{Result = 'Inconclusive'}
                )
            }

            Write-NovaPesterTestResultReport -TestResult $testResult -OutputPath $OutputPath

            [xml]$report = Get-Content -LiteralPath $OutputPath -Raw
            $testResultsNode = $report.SelectSingleNode('/test-results')
            $testSuiteNode = $report.SelectSingleNode('/test-results/test-suite')

            $testResultsNode.name | Should -Be 'NovaModuleTools'
            $testResultsNode.total | Should -Be '4'
            $testResultsNode.failures | Should -Be '0'
            $testResultsNode.inconclusive | Should -Be '1'
            $testResultsNode.skipped | Should -Be '1'
            $testSuiteNode.result | Should -Be 'Success'
            $testSuiteNode.success | Should -Be 'True'
            $testSuiteNode.passed | Should -Be '2'
        }
    }

    It 'Write-NovaPesterTestResultReport writes a failure NUnit-style report when failed tests are present' {
        $outputPath = Join-Path $TestDrive 'failure-report.xml'

        InModuleScope $script:moduleName -Parameters @{OutputPath = $outputPath} {
            param($OutputPath)

            $testResult = [pscustomobject]@{
                Tests = @(
                    [pscustomobject]@{Result = 'Passed'}
                    [pscustomobject]@{Result = 'Failed'}
                )
            }

            Write-NovaPesterTestResultReport -TestResult $testResult -OutputPath $OutputPath -TestSuiteName 'FocusedSuite'

            [xml]$report = Get-Content -LiteralPath $OutputPath -Raw
            $testResultsNode = $report.SelectSingleNode('/test-results')
            $testSuiteNode = $report.SelectSingleNode('/test-results/test-suite')

            $testResultsNode.name | Should -Be 'FocusedSuite'
            $testResultsNode.failures | Should -Be '1'
            $testSuiteNode.result | Should -Be 'Failure'
            $testSuiteNode.success | Should -Be 'False'
            $testSuiteNode.failed | Should -Be '1'
        }
    }

    It 'Write-NovaPesterTestResultArtifact returns without writing when the result has no Tests property' {
        InModuleScope $script:moduleName {
            Mock Get-Command {throw 'Get-Command should not be called when Tests is missing.'}

            {Write-NovaPesterTestResultArtifact -TestResult ([pscustomobject]@{Summary = 'no tests'}) -OutputPath '/tmp/unused.xml'} | Should -Not -Throw

            Assert-MockCalled Get-Command -Times 0
        }
    }

    It 'Write-NovaPesterTestResultArtifact uses the provided report writer when one is supplied' {
        InModuleScope $script:moduleName {
            $calls = [System.Collections.Generic.List[object]]::new()
            $reportWriter = {
                param($TestResult, $OutputPath)

                $calls.Add([pscustomobject]@{
                    TestResult = $TestResult
                    OutputPath = $OutputPath
                }) | Out-Null
            }.GetNewClosure()
            $testResult = [pscustomobject]@{Tests = @([pscustomobject]@{Result = 'Passed'})}

            Write-NovaPesterTestResultArtifact -TestResult $testResult -OutputPath '/tmp/provided.xml' -ReportWriter $reportWriter

            $calls.Count | Should -Be 1
            $calls[0].OutputPath | Should -Be '/tmp/provided.xml'
            $calls[0].TestResult.Tests[0].Result | Should -Be 'Passed'
        }
    }

    It 'Write-NovaPesterTestResultArtifact resolves the default report writer when none is supplied' {
        InModuleScope $script:moduleName {
            Mock Get-Command {
                [pscustomobject]@{
                    ScriptBlock = {
                        param($TestResult, $OutputPath)

                        return [pscustomobject]@{
                            TestCount = @($TestResult.Tests).Count
                            OutputPath = $OutputPath
                        }
                    }
                }
            } -ParameterFilter {
                $Name -eq 'Write-NovaPesterTestResultReport' -and $CommandType -eq 'Function'
            }

            $result = Write-NovaPesterTestResultArtifact -TestResult ([pscustomobject]@{Tests = @([pscustomobject]@{Result = 'Passed'})}) -OutputPath '/tmp/default.xml'

            $result.TestCount | Should -Be 1
            $result.OutputPath | Should -Be '/tmp/default.xml'
            Assert-MockCalled Get-Command -Times 1 -ParameterFilter {
                $Name -eq 'Write-NovaPesterTestResultReport' -and $CommandType -eq 'Function'
            }
        }
    }

    It 'Initialize-NovaPesterExecutionConfiguration applies returned overrides when <Name>' -ForEach @(
        @{
            Name = 'both verbosity and render mode are provided'
            Override = [pscustomobject]@{Verbosity = 'Detailed'; RenderMode = 'Plaintext'}
            BoundParameters = @{OutputVerbosity = 'Detailed'; OutputRenderMode = 'Plaintext'}
            ExpectedVerbosity = 'Detailed'
            ExpectedRenderMode = 'Plaintext'
        }
        @{
            Name = 'only render mode is provided'
            Override = [pscustomobject]@{Verbosity = $null; RenderMode = 'Ansi'}
            BoundParameters = @{OutputRenderMode = 'Ansi'}
            ExpectedVerbosity = 'Normal'
            ExpectedRenderMode = 'Ansi'
        }
    ) {
        $pesterConfig = [pscustomobject]@{
            Output = [pscustomobject]@{
                Verbosity = 'Normal'
                RenderMode = 'Auto'
            }
            TestResult = [pscustomobject]@{Enabled = $true}
        }

        InModuleScope $script:moduleName -Parameters @{TestCase = $_; PesterConfig = $pesterConfig} {
            param($TestCase, $PesterConfig)

            Mock Get-NovaPesterOutputOptionOverride {$TestCase.Override}

            Initialize-NovaPesterExecutionConfiguration -PesterConfig $PesterConfig -BoundParameters $TestCase.BoundParameters

            $PesterConfig.Output.Verbosity | Should -Be $TestCase.ExpectedVerbosity
            $PesterConfig.Output.RenderMode | Should -Be $TestCase.ExpectedRenderMode
            $PesterConfig.TestResult.Enabled | Should -BeFalse
            Assert-MockCalled Get-NovaPesterOutputOptionOverride -Times 1
        }
    }

    It 'Initialize-NovaPesterExecutionConfiguration preserves unsupported settings when no overrides are returned' {
        $pesterConfig = [pscustomobject]@{
            Output = [pscustomobject]@{
                Verbosity = 'Normal'
                RenderMode = 'Auto'
            }
            TestResult = [pscustomobject]@{Summary = 'No Enabled property'}
        }

        InModuleScope $script:moduleName -Parameters @{PesterConfig = $pesterConfig} {
            param($PesterConfig)

            Mock Get-NovaPesterOutputOptionOverride {$null}

            Initialize-NovaPesterExecutionConfiguration -PesterConfig $PesterConfig -BoundParameters @{}

            $PesterConfig.Output.Verbosity | Should -Be 'Normal'
            $PesterConfig.Output.RenderMode | Should -Be 'Auto'
            $PesterConfig.TestResult.PSObject.Properties.Name | Should -Not -Contain 'Enabled'
            Assert-MockCalled Get-NovaPesterOutputOptionOverride -Times 1
        }
    }
}
