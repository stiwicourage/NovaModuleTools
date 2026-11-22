function Get-ProjectJsonValueTypeName {
    [CmdletBinding()]
    [OutputType([string])]
    param([AllowNull()]$Value)

    if ($null -eq $Value) {
        return 'null'
    }

    return $Value.GetType().FullName
}
