BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/BuildModule.ps1')

    . (Join-Path $PSScriptRoot 'BuildModule.TestSupport.ps1')
}

Describe 'Build-Module' {
    BeforeEach {
        $script:tmp = Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path (Join-Path $script:tmp 'src/public') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:tmp 'src/private') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:tmp 'src/classes') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:tmp 'dist') -Force | Out-Null
        $script:ctx = [pscustomobject]@{
            PublicDir = Join-Path $script:tmp 'src/public'
            PrivateDir = Join-Path $script:tmp 'src/private'
            ClassesDir = Join-Path $script:tmp 'src/classes'
            ModuleFilePSM1 = Join-Path $script:tmp 'dist/Out.psm1'
        }
    }
    AfterEach { Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue }

    It 'throws when no source files exist' {
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Test-ProjectSchema {}
        Mock Add-ProjectPreambleToModuleBuilder {}
        Mock Get-ProjectScriptFile { @() }
        { Build-Module -ProjectInfo ([pscustomobject]@{}) } | Should -Throw -ErrorId 'Nova.Environment.BuildSourceFilesNotFound'
    }

    It 'writes the psm1 when source files exist' {
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Test-ProjectSchema {}
        Mock Add-ProjectPreambleToModuleBuilder {}
        Set-Content -Path (Join-Path $script:ctx.PublicDir 'A.ps1') -Value 'function A {}'
        Mock Get-ProjectScriptFile { @(Get-Item (Join-Path $script:ctx.PublicDir 'A.ps1')) }
        Mock Add-ScriptFileContentToModuleBuilder { param($Builder, $ProjectInfo, $File) [void]$Builder.Append("function A {}") }
        Build-Module -ProjectInfo ([pscustomobject]@{})
        Test-Path $script:ctx.ModuleFilePSM1 | Should -BeTrue
        Get-Content $script:ctx.ModuleFilePSM1 -Raw | Should -Match 'function A'
    }

    It 'stops with friendly error when psm1 write fails' {
        Mock Get-NovaBuildProjectInfo { $script:ctx }
        Mock Test-ProjectSchema {}
        Mock Add-ProjectPreambleToModuleBuilder {}
        Set-Content -Path (Join-Path $script:ctx.PublicDir 'A.ps1') -Value 'function A {}'
        Mock Get-ProjectScriptFile { @(Get-Item (Join-Path $script:ctx.PublicDir 'A.ps1')) }
        Mock Add-ScriptFileContentToModuleBuilder {}
        Mock Set-Content { throw 'write failed' } -ParameterFilter { $Path -eq $script:ctx.ModuleFilePSM1 }
        { Build-Module -ProjectInfo ([pscustomobject]@{}) } | Should -Throw -ErrorId 'Nova.Dependency.ModulePsm1CreationFailed'
    }
}
