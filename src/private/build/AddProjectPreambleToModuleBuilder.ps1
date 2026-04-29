function Add-ProjectPreambleToModuleBuilder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    if ($ProjectInfo.Preamble.Count -eq 0) {
        return
    }

    foreach ($line in $ProjectInfo.Preamble) {
        $Builder.AppendLine($line) | Out-Null
    }

    $Builder.AppendLine() | Out-Null
}
