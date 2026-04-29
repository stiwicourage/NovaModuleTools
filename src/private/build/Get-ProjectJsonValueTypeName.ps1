function Get-ProjectJsonValueTypeName {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return 'null'
    }

    return $Value.GetType().FullName
}
