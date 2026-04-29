function Get-IndexableSourceFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$File
    )

    return @($File | Where-Object {$_ -and -not [string]::IsNullOrWhiteSpace($_.FullName)})
}
