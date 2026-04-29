function Assert-BuiltModuleHasNoDuplicateFunctionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $psm1Path = $ProjectInfo.ModuleFilePSM1
    if (-not (Test-Path -LiteralPath $psm1Path)) {
        Stop-NovaOperation -Message "Built module file not found: $psm1Path" -ErrorId 'Nova.Environment.BuiltModuleFileNotFound' -Category ObjectNotFound -TargetObject $psm1Path
    }

    $parsed = Get-PowerShellAstFromFile -Path $psm1Path
    if ($parsed.Errors -and $parsed.Errors.Count -gt 0) {
        $messages = @($parsed.Errors | ForEach-Object { $_.Message }) -join '; '
        Stop-NovaOperation -Message "Built module contains parse errors and cannot be validated for duplicates. File: $psm1Path. Errors: $messages" -ErrorId 'Nova.Configuration.BuiltModuleDuplicateValidationParseFailed' -Category ParserError -TargetObject $psm1Path
    }

    $topLevelFunctions = @(Get-TopLevelFunctionAst -Ast $parsed.Ast)
    if ($topLevelFunctions.Count -eq 0) {
        Stop-NovaOperation -Message 'No functions found to build. Add a function to the source file.' -ErrorId 'Nova.Workflow.BuiltModuleFunctionListEmpty' -Category InvalidOperation -TargetObject $psm1Path
    }

    $duplicates = Get-DuplicateFunctionGroup -FunctionAst $topLevelFunctions

    if (-not $duplicates) {
        return
    }

    $sourceFiles = Get-ProjectScriptFile -ProjectInfo $ProjectInfo
    $sourceIndex = Get-FunctionSourceIndex -File $sourceFiles

    $errorText = Format-DuplicateFunctionErrorMessage -Psm1Path $psm1Path -DuplicateGroup $duplicates -SourceIndex $sourceIndex
    Stop-NovaOperation -Message $errorText -ErrorId 'Nova.Validation.BuiltModuleDuplicateFunctionName' -Category InvalidData -TargetObject $psm1Path
}
