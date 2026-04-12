BeforeAll {
    . (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'CodeSceneCoverageMap.ps1')
    . (Join-Path $PSScriptRoot '..' 'scripts' 'build' 'ci' 'CodeSceneCoverageXml.ps1')
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

        {
            Convert-CoberturaCoverageToSourcePath -CoveragePath $coveragePath -BuiltModulePath $builtModulePath -RepoRoot $repoRoot
        } | Should -Throw "Could not find any '# Source:' markers*"
    }
}

