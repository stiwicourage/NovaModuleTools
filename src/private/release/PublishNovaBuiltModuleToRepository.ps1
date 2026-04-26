function Publish-NovaBuiltModuleToRepository {
    [CmdletBinding(SupportsShouldProcess = $true)]
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
