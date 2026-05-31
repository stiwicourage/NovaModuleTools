function Get-NovaPesterRunPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$ProjectInfo,
        [Parameter()][string]$IncludePattern = '*.Tests.ps1',
        [Parameter()][string[]]$ExcludePattern = @()
    )

    $testFile = Get-ChildItem -LiteralPath $ProjectInfo.TestsDir -File -Filter $IncludePattern -Recurse:$ProjectInfo.BuildRecursiveFolders
    $testPath = $testFile | Sort-Object -Property FullName | ForEach-Object -Process { $_.FullName }

    if ($ExcludePattern.Count -eq 0) {
        return @($testPath)
    }

    return @(
        $testPath | Where-Object -FilterScript {
            -not (Test-NovaPesterExcludedTestPath -TestPath $_ -ExcludePattern $ExcludePattern)
        }
    )
}

function Test-NovaPesterExcludedTestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestPath,
        [Parameter(Mandatory)][string[]]$ExcludePattern
    )

    $testFileName = [System.IO.Path]::GetFileName($TestPath)
    foreach ($pattern in $ExcludePattern) {
        $wildcardPattern = [System.Management.Automation.WildcardPattern]::new(
            $pattern,
            [System.Management.Automation.WildcardOptions]::IgnoreCase
        )

        if ($wildcardPattern.IsMatch($testFileName) -or $wildcardPattern.IsMatch($TestPath)) {
            return $true
        }
    }

    return $false
}
