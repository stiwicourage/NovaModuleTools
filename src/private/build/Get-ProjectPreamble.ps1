function Get-ProjectPreamble {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ProjectData
    )

    if (-not $ProjectData.ContainsKey('Preamble')) {
        return @()
    }

    $preamble = $ProjectData.Preamble
    if ($preamble -is [string] -or $preamble -isnot [System.Collections.IEnumerable]) {
        $typeName = Get-ProjectJsonValueTypeName -Value $preamble
        $valueText = Format-ProjectJsonValue -Value $preamble
        Stop-NovaOperation -Message "Invalid project.json Preamble value: expected top-level Preamble as string[] but found type '$typeName' with value $valueText. Preamble must be a top-level project.json array of strings." -ErrorId 'Nova.Configuration.ProjectPreambleInvalidType' -Category InvalidData -TargetObject $preamble
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'
    $index = 0
    foreach ($item in @($preamble)) {
        if ($item -isnot [string]) {
            $typeName = Get-ProjectJsonValueTypeName -Value $item
            $valueText = Format-ProjectJsonValue -Value $item
            Stop-NovaOperation -Message "Invalid project.json Preamble value: expected top-level Preamble as string[] but found entry at index $index with type '$typeName' and value $valueText. Preamble must be a top-level project.json array of strings." -ErrorId 'Nova.Configuration.ProjectPreambleInvalidType' -Category InvalidData -TargetObject $item
        }

        $lines.Add($item)
        $index++
    }

    return @($lines)
}
