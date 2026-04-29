function Get-LocalModulePathEntryList {
    $separator = [IO.Path]::PathSeparator
    $modulePath = Get-NovaEnvironmentVariableValue -Name 'PSModulePath'

    if ( [string]::IsNullOrWhiteSpace($modulePath)) {
        return @()
    }

    return @(
    $modulePath -split $separator |
            ForEach-Object {$_.Trim()} |
            Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |
            Select-Object -Unique
    )
}
