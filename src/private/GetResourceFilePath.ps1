function Get-ResourceFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FileName
    )

    $candidates = @(
        [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "resources/$FileName")),
        [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../resources/$FileName"))
    ) | Select-Object -Unique

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "Resource file not found: $FileName. Checked: $($candidates -join ', ')"
}

