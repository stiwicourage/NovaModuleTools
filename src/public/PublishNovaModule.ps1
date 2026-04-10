function Publish-NovaModule {
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(ParameterSetName = 'Local')]
        [switch]$Local,

        [Parameter(ParameterSetName = 'Repository', Mandatory)]
        [string]$Repository,

        [string]$ModuleDirectoryPath,
        [string]$ApiKey
    )

    Invoke-NovaBuild
    Test-NovaBuild

    if ($Local) {
        Write-Verbose 'Using local publish mode.'
    }

    if ($PSCmdlet.ParameterSetName -eq 'Repository') {
        Publish-NovaBuiltModule -Repository $Repository -ApiKey $ApiKey
        return
    }

    Publish-NovaBuiltModule -ModuleDirectoryPath $ModuleDirectoryPath
}


