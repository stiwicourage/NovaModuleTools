function ConvertFrom-NovaNotificationCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return Get-NovaCliModeArgumentValue -Arguments $Arguments -Definition ([pscustomobject]@{
        EmptyResult = 'status'
        TokenMap = @{
            '--enable' = 'enable'
            '-e' = 'enable'
            '--disable' = 'disable'
            '-d' = 'disable'
        }
        Usage = [pscustomobject]@{
            Message = "Unsupported 'nova notification' usage. Use 'nova notification', 'nova notification --enable'/'nova notification -e', or 'nova notification --disable'/'nova notification -d'."
            ErrorId = 'Nova.Validation.UnsupportedNotificationCliUsage'
        }
        UnknownArgumentUsesUsageError = $false
    })
}
