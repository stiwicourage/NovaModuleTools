function Publish-NovaBuiltModuleToRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ProjectInfo,

        [Parameter(Mandatory)]
        [string]$Repository,

        [string]$ApiKey
    )

    $resolvedApiKey = $ApiKey
    if ($Repository -eq 'PSGallery' -and [string]::IsNullOrWhiteSpace($resolvedApiKey)) {
        $resolvedApiKey = $env:PSGALLERY_API
    }

    $publishParams = @{
        Path = $ProjectInfo.OutputModuleDir
        Repository = $Repository
        Verbose = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($resolvedApiKey)) {
        $publishParams.ApiKey = $resolvedApiKey
    }

    Publish-PSResource @publishParams
}

