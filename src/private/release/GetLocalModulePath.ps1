function Get-LocalModulePath {
    $modulePaths = Get-LocalModulePathEntryList
    $matchPattern = Get-LocalModulePathPattern
    $errorMessage = Get-LocalModulePathErrorMessage -MatchPattern $matchPattern
    $errorDetails = [pscustomobject]@{
        Message = $errorMessage
        ErrorId = 'Nova.Environment.LocalModulePathNotFound'
        Category = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        TargetObject = $matchPattern
    }

    return Find-LocalModulePathMatch -ModulePaths $modulePaths -MatchPattern $matchPattern -ErrorDetails $errorDetails
}
