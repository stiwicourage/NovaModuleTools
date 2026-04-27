function Get-NovaPublishRepositoryDefaultApiKeyEnvironmentVariable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Repository
    )

    if ( $Repository.Equals('PSGallery', [System.StringComparison]::OrdinalIgnoreCase)) {
        return 'PSGALLERY_API'
    }

    return $null
}

function Publish-NovaBuiltModuleToRepository {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$ProjectInfo,

        [Parameter(Mandatory)]
        [string]$Repository,

        [string]$ApiKey
    )

    $resolvedApiKey = Resolve-NovaSecretValue -SecretSources ([pscustomobject]@{
        ExplicitValue = $ApiKey
        DefaultEnvironmentVariableName = Get-NovaPublishRepositoryDefaultApiKeyEnvironmentVariable -Repository $Repository
    })

    $publishParams = @{
        Path = $ProjectInfo.OutputModuleDir
        Repository = $Repository
    }

    if ( $PSBoundParameters.ContainsKey('Verbose')) {
        $publishParams.Verbose = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($resolvedApiKey)) {
        $publishParams.ApiKey = $resolvedApiKey
    }

    if (-not $PSCmdlet.ShouldProcess($Repository, 'Publish built module to repository')) {
        return
    }

    Publish-PSResource @publishParams
}
