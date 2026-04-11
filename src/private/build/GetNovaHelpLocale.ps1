function Get-NovaHelpLocale {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo[]]$HelpMarkdownFiles
    )

    $locales = foreach ($file in $HelpMarkdownFiles) {
        $localeLine = Get-Content -LiteralPath $file.FullName -TotalCount 20 | Where-Object {$_ -match '^Locale:\s*(.+)$'} | Select-Object -First 1
        if (-not [string]::IsNullOrWhiteSpace($localeLine)) {
            $localeLine -replace '^Locale:\s*', ''
        }
    }

    $distinctLocales = @($locales | Where-Object {-not [string]::IsNullOrWhiteSpace($_)} | Select-Object -Unique)

    if ($distinctLocales.Count -gt 1) {
        throw "Multiple help locales found in docs metadata: $( $distinctLocales -join ', ' )"
    }

    if ($distinctLocales.Count -eq 1) {
        return $distinctLocales[0]
    }

    return 'en-US'
}

