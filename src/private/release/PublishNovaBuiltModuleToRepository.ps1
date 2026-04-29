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

function Get-NovaRepositoryPublishParameterMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$Repository,
        [string]$ApiKey,
        [Parameter(Mandatory)][bool]$VerboseRequested
    )

    $publishParams = @{
        Path = $ProjectInfo.OutputModuleDir
        Repository = $Repository
    }
    if ($VerboseRequested) {
        $publishParams.Verbose = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $publishParams.ApiKey = $ApiKey
    }

    return $publishParams
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
    $publishParams = Get-NovaRepositoryPublishParameterMap -ProjectInfo $ProjectInfo -Repository $Repository -ApiKey $resolvedApiKey -VerboseRequested:$PSBoundParameters.ContainsKey('Verbose')

    if (-not $PSCmdlet.ShouldProcess($Repository, 'Publish built module to repository')) {
        return
    }

    Invoke-NovaRepositoryPublishCommand -PublishParameters $publishParams
}
