function Get-LocalModulePathEntryList {
    $separator = [IO.Path]::PathSeparator

    return @(
    $env:PSModulePath -split $separator |
            ForEach-Object {$_.Trim()} |
            Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |
            Select-Object -Unique
    )
}
