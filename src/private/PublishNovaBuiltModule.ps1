function Publish-NovaBuiltModule {
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(ParameterSetName = 'Repository')]
        [string]$Repository,

        [string]$ModuleDirectoryPath,
        [string]$ApiKey
    )

    $projectInfo = Get-MTProjectInfo

    if (-not (Test-Path -LiteralPath $projectInfo.OutputModuleDir)) {
        throw 'Dist folder is empty, build the module before running publish command'
    }

    if ($PSCmdlet.ParameterSetName -eq 'Repository') {
        $resolvedApiKey = $ApiKey
        if ($Repository -eq 'PSGallery' -and [string]::IsNullOrWhiteSpace($resolvedApiKey)) {
            $resolvedApiKey = $env:PSGALLERY_API
        }

        $publishParams = @{
            Path = $projectInfo.OutputModuleDir
            Repository = $Repository
            Verbose = $true
        }

        if (-not [string]::IsNullOrWhiteSpace($resolvedApiKey)) {
            $publishParams.ApiKey = $resolvedApiKey
        }

        Publish-PSResource @publishParams
        return
    }

    Publish-MTLocal -ModuleDirectoryPath $ModuleDirectoryPath
}

