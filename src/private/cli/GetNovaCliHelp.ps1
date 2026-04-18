function Get-NovaCliHelp {
    $helpPath = Get-ResourceFilePath -FileName 'cli/NovaCliHelp.txt'
    return Get-Content -LiteralPath $helpPath -Raw -ErrorAction Stop
}