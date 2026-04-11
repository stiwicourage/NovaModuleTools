function Get-LocalModulePath {
    $modulePaths = Get-LocalModulePathEntryList
    $matchPattern = Get-LocalModulePathPattern
    $errorMessage = Get-LocalModulePathErrorMessage -MatchPattern $matchPattern

    return Find-LocalModulePathMatch -ModulePaths $modulePaths -MatchPattern $matchPattern -ErrorMessage $errorMessage
}
