function Get-ExampleGreeting {
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$AsObject
    )

    $configuration = Get-ExampleConfiguration
    $audience = if ( [string]::IsNullOrWhiteSpace($Name)) {
        $configuration.DefaultAudience
    }
    else {
        $Name
    }
    $message = '{0}, {1}!' -f $configuration.GreetingPrefix, $audience

    if (-not $AsObject) {
        return $message
    }

    return [pscustomobject]@{
        Message = $message
        Audience = $audience
        ConfigurationPath = $configuration.ConfigurationPath
    }
}
