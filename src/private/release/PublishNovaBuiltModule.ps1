function Publish-NovaBuiltModule {
    [CmdletBinding(DefaultParameterSetName = 'Local')]
    param(
        [Parameter(ParameterSetName = 'Repository')]
        [string]$Repository,

        [string]$ModuleDirectoryPath,
        [string]$ApiKey,
        [pscustomobject]$ProjectInfo = (Get-NovaProjectInfo)
    )

    if (-not (Test-Path -LiteralPath $ProjectInfo.OutputModuleDir)) {
        Stop-NovaOperation -Message 'Dist folder is empty, build the module before running publish command' -ErrorId 'Nova.Environment.ReleaseBuildOutputNotFound' -Category ObjectNotFound -TargetObject $ProjectInfo.OutputModuleDir
    }

    if ( $PSBoundParameters.ContainsKey('Repository')) {
        Publish-NovaBuiltModuleToRepository -ProjectInfo $ProjectInfo -Repository $Repository -ApiKey $ApiKey
        return
    }

    $resolvedModuleDirectoryPath = $ModuleDirectoryPath
    if ( [string]::IsNullOrWhiteSpace($resolvedModuleDirectoryPath)) {
        $resolvedModuleDirectoryPath = Resolve-NovaLocalPublishPath -ModuleDirectoryPath $ModuleDirectoryPath
    }

    Publish-NovaBuiltModuleToDirectory -ProjectInfo $ProjectInfo -ModuleDirectoryPath $resolvedModuleDirectoryPath
}
