function Get-NovaEnvironmentVariableValue {
    [CmdletBinding()]
    param(
        [string]$Name
    )

    if ( [string]::IsNullOrWhiteSpace($Name)) {
        return $null
    }

    return [System.Environment]::GetEnvironmentVariable($Name.Trim())
}
