function ConvertFrom-NovaVersionCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return Get-NovaCliModeArgumentValue -Arguments $Arguments -Definition ([pscustomobject]@{
        EmptyResult = @{Installed = $false}
        TokenMap = @{
            '--installed' = @{Installed = $true}
            '-i' = @{Installed = $true}
        }
        Usage = [pscustomobject]@{
            Message = "Unsupported 'nova version' usage. Use 'nova version' or 'nova version --installed'/'nova version -i'."
            ErrorId = 'Nova.Validation.UnsupportedVersionCliUsage'
        }
        UnknownArgumentUsesUsageError = $true
    })
}
