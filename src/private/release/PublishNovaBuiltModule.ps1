function Publish-NovaBuiltModule {
    [CmdletBinding(DefaultParameterSetName = 'Local', SupportsShouldProcess = $true)]
    param(
        [Parameter(ParameterSetName = 'Repository')]
        [string]$Repository,

        [string]$ModuleDirectoryPath,
        [string]$ApiKey,
        [pscustomobject]$ProjectInfo = (Get-NovaProjectInfo)
    )

    if (-not (Test-Path -LiteralPath $ProjectInfo.OutputModuleDir)) {
        throw 'Dist folder is empty, build the module before running publish command'
    }

    if ( $PSBoundParameters.ContainsKey('Repository')) {
        $shouldRun = $PSCmdlet.ShouldProcess($Repository, 'Publish built module to repository')
        if (-not $shouldRun -and -not $WhatIfPreference) {
            return
        }

        Publish-NovaBuiltModuleToRepository -ProjectInfo $ProjectInfo -Repository $Repository -ApiKey $ApiKey -WhatIf:$WhatIfPreference -Confirm:$false
        return
    }

    $resolvedModuleDirectoryPath = $ModuleDirectoryPath
    if ( [string]::IsNullOrWhiteSpace($resolvedModuleDirectoryPath)) {
        $resolvedModuleDirectoryPath = Resolve-NovaLocalPublishPath -ModuleDirectoryPath $ModuleDirectoryPath
    }

    $shouldRun = $PSCmdlet.ShouldProcess($resolvedModuleDirectoryPath, 'Publish built module to local directory')
    if (-not $shouldRun -and -not $WhatIfPreference) {
        return
    }

    Publish-NovaBuiltModuleToDirectory -ProjectInfo $ProjectInfo -ModuleDirectoryPath $resolvedModuleDirectoryPath -WhatIf:$WhatIfPreference -Confirm:$false
}
