function Get-ExampleConfiguration {
    [CmdletBinding()]
    param()

    $configurationPath = Join-Path $PSScriptRoot 'resources/greeting-config.json'
    if (-not (Test-Path -LiteralPath $configurationPath)) {
        Stop-NovaOperation -Message "Example configuration not found: $configurationPath" -ErrorId 'Nova.Environment.ExampleConfigurationNotFound' -Category ObjectNotFound -TargetObject $configurationPath
    }

    $configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
    return [pscustomobject]@{
        GreetingPrefix = $configuration.GreetingPrefix
        DefaultAudience = $configuration.DefaultAudience
        ConfigurationPath = $configurationPath
    }
}
