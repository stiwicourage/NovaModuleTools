function Test-NovaCliBumpConfirmationIsEnabled {
    [CmdletBinding()]
    param()

    return $env:NOVA_CLI_CONFIRM_BUMP -eq '1'
}

