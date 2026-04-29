function ConvertFrom-NovaUpdateCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return Get-NovaCliModeArgumentValue -Arguments $Arguments -Definition ([pscustomobject]@{
        EmptyResult = @{}
        TokenMap = @{}
        Usage = [pscustomobject]@{
            Message = "Unsupported 'nova update' usage. Use 'nova update'."
            ErrorId = 'Nova.Validation.UnsupportedUpdateCliUsage'
        }
        UnknownArgumentUsesUsageError = $true
    })
}
