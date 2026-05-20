BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    . (Join-Path $projectRoot 'src/private/quality/duplicates/GetTopLevelFunctionAst.ps1')

    function Get-TestAst {
        param([Parameter(Mandatory)][string]$ScriptText)

        $tokens = $null
        $errors = $null
        return [System.Management.Automation.Language.Parser]::ParseInput($ScriptText, [ref]$tokens, [ref]$errors)
    }
}

Describe 'Get-TopLevelFunctionAst' {
    It 'returns only top-level functions when nested functions are present' {
        $ast = Get-TestAst -ScriptText @'
function Get-Outer {
    function Get-Nested {
    }

    Get-Nested
}

function Get-Second {
}
'@

        $result = Get-TopLevelFunctionAst -Ast $ast

        @($result.Name) | Should -Be @('Get-Outer', 'Get-Second')
    }

    It 'returns an empty collection when the script has no functions' {
        $ast = Get-TestAst -ScriptText '$value = 1'

        @(Get-TopLevelFunctionAst -Ast $ast).Count | Should -Be 0
    }
}
