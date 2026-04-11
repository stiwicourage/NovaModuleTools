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

    $projectInfo = Get-NovaProjectInfo
    $publishParams = @{ProjectInfo = $projectInfo}

    if ( $PSBoundParameters.ContainsKey('Repository')) {
        $publishAction = (Get-Command -Name Publish-NovaBuiltModuleToRepository -CommandType Function).ScriptBlock
        $publishParams.Repository = $Repository
        $publishParams.ApiKey = $ApiKey
    }
    else {
        $publishAction = (Get-Command -Name Publish-NovaBuiltModuleToDirectory -CommandType Function).ScriptBlock
        if ($Local) {
            Write-Verbose 'Using local publish mode.'
        }

        $resolvedModuleDirectoryPath = $ModuleDirectoryPath
        if ( [string]::IsNullOrWhiteSpace($resolvedModuleDirectoryPath)) {
            $resolvedModuleDirectoryPath = Get-LocalModulePath
        }

        $publishParams.ModuleDirectoryPath = $resolvedModuleDirectoryPath
        Write-Verbose "Using $resolvedModuleDirectoryPath as path"
    }

    Invoke-NovaBuild
    Test-NovaBuild

    & $publishAction @publishParams

    if (-not $PSBoundParameters.ContainsKey('Repository')) {
        Write-Verbose 'Module copy to local path complete, Refresh session or import module manually'
    }
}


