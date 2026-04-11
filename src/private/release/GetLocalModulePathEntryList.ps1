function Get-LocalModulePathEntryList {
    $separator = [IO.Path]::PathSeparator

    return @(
    $env:PSModulePath -split $separator |
            ForEach-Object {$_.Trim()} |
            Select-Object -Unique
    )
}
