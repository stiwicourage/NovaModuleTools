BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetOrCreateHashtableList.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/AddFunctionSourceIndexEntry.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetPowerShellAstFromFile.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetTopLevelFunctionAst.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetTopLevelFunctionAstFromFile.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetIndexableFunctionAstFromFile.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/AddFunctionSourceIndexEntryFromFile.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetIndexableSourceFile.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetFunctionSourceIndex.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetDuplicateFunctionGroup.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetDuplicateFunctionSourceLine.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/FormatDuplicateFunctionErrorMessage.ps1')
    . (Join-Path $projectRoot 'src/private/quality/duplicates/AssertBuiltModuleHasNoDuplicateFunctionNames.ps1')
    . (Join-Path $projectRoot 'src/private/build/GetProjectScriptFiles.ps1')
    . (Join-Path $projectRoot 'src/private/build/GetOrderedScriptFileForDirectory.ps1')
    . (Join-Path $projectRoot 'src/private/shared/GetNormalizedRelativePath.ps1')

    . (Join-Path $PSScriptRoot 'AssertBuiltModuleHasNoDuplicateFunctionNames.TestSupport.ps1')
}

Describe 'Assert-BuiltModuleHasNoDuplicateFunctionName' {
    BeforeEach {
        $script:projectRoot = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
    }

    AfterEach {
        Remove-Item -LiteralPath $script:projectRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'returns when the built module does not contain duplicate function names' {
        $projectInfo = New-DuplicateValidationProjectInfo -ProjectRoot $script:projectRoot -ModuleContent @'
function Get-Alpha {}
function Get-Beta {}
'@ -SourceFileMap @{
            'src/public/GetAlpha.ps1' = 'function Get-Alpha {}'
            'src/public/GetBeta.ps1' = 'function Get-Beta {}'
        }

        { Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $projectInfo } | Should -Not -Throw
    }

    It 'throws a source-mapped error when the built module contains duplicate top-level function names' {
        $projectInfo = New-DuplicateValidationProjectInfo -ProjectRoot $script:projectRoot -ModuleContent @'
function Get-Alpha {}
function get-alpha {}
'@ -SourceFileMap @{
            'src/public/GetAlpha.ps1' = @'
function Get-Alpha {
    param()
}
'@
            'src/private/GetAlphaOverride.ps1' = @'
function Get-Alpha {
    param()
}
'@
        }

        try {
            Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $projectInfo
            throw 'Expected duplicate-function validation to fail.'
        } catch {
            $_.FullyQualifiedErrorId | Should -Be 'Nova.Validation.BuiltModuleDuplicateFunctionName'
            $_.Exception.Message | Should -Match 'Duplicate top-level function names detected'
            $_.Exception.Message | Should -Match 'dist line'
            $_.Exception.Message | Should -Match 'source files'
            $_.Exception.Message | Should -Match 'src/public/GetAlpha\.ps1'
            $_.Exception.Message | Should -Match 'src/private/GetAlphaOverride\.ps1'
        }
    }

    It 'throws a parse-specific error when the built module cannot be parsed' {
        $projectInfo = New-DuplicateValidationProjectInfo -ProjectRoot $script:projectRoot -ModuleContent @'
function Get-Alpha {
'@ -SourceFileMap @{
            'src/public/GetAlpha.ps1' = 'function Get-Alpha {}'
        }

        try {
            Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $projectInfo
            throw 'Expected parse validation to fail.'
        } catch {
            $_.FullyQualifiedErrorId | Should -Be 'Nova.Configuration.BuiltModuleDuplicateValidationParseFailed'
            $_.Exception.Message | Should -Match 'contains parse errors'
            $_.Exception.Message | Should -Match 'NovaModuleTools\.psm1'
        }
    }
}
