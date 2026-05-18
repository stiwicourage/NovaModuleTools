function Get-ExampleConfigurationPath {
    [CmdletBinding()]
    param(
        [string]$BasePath = $PSScriptRoot
    )

    $candidatePathList = @(
        [System.IO.Path]::GetFullPath((Join-Path $BasePath 'resources/greeting-config.json'))
        [System.IO.Path]::GetFullPath((Join-Path $BasePath '../resources/greeting-config.json'))
    ) | Select-Object -Unique

    foreach ($candidatePath in $candidatePathList) {
        if (Test-Path -LiteralPath $candidatePath) {
            return $candidatePath
        }
    }

    Stop-NovaOperation -Message "Example configuration not found. Checked: $( $candidatePathList -join ', ' )" -ErrorId 'Nova.Environment.ExampleConfigurationNotFound' -Category ObjectNotFound -TargetObject 'resources/greeting-config.json'
}

function Get-ExampleConfiguration {
    [CmdletBinding()]
    param()

    $configurationPath = Get-ExampleConfigurationPath
    $configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
    return [pscustomobject]@{
        GreetingPrefix = $configuration.GreetingPrefix
        DefaultAudience = $configuration.DefaultAudience
        ConfigurationPath = $configurationPath
    }
}
