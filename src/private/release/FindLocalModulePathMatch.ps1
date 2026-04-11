function Find-LocalModulePathMatch {
    param(
        [Parameter(Mandatory)][string[]]$ModulePaths,
        [Parameter(Mandatory)][string]$MatchPattern,
        [Parameter(Mandatory)][string]$ErrorMessage
    )

    $result = $ModulePaths |
            Where-Object {$_ -match $MatchPattern} |
            Select-Object -First 1

    if ($result -and (Test-Path $result)) {
        return $result
    }

    throw $ErrorMessage
}
