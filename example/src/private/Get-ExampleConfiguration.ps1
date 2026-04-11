function Get-ExampleConfiguration {
    [CmdletBinding()]
    param()

    $configurationPath = Join-Path $PSScriptRoot 'resources/greeting-config.json'
    if (-not (Test-Path -LiteralPath $configurationPath)) {
        throw "Example configuration not found: $configurationPath"
    }

    $configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
    return [pscustomobject]@{
        GreetingPrefix = $configuration.GreetingPrefix
        DefaultAudience = $configuration.DefaultAudience
        ConfigurationPath = $configurationPath
    }
}
