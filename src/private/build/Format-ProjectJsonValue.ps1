function Format-ProjectJsonValue {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return 'null'
    }

    try {
        return ($Value | ConvertTo-Json -Compress -Depth 10)
    }
    catch {
        return [string]$Value
    }
}
