function Resolve-NovaPublishInvocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string]$Repository,
        [string]$ModuleDirectoryPath,
        [string]$ApiKey
    )

    $publishParameters = @{ProjectInfo = $ProjectInfo}
    if (-not [string]::IsNullOrWhiteSpace($Repository)) {
        $publishParameters.Repository = $Repository
        $publishParameters.ApiKey = $ApiKey

        return [pscustomobject]@{
            Action = (Get-Command -Name Publish-NovaBuiltModuleToRepository -CommandType Function).ScriptBlock
            Parameters = $publishParameters
            Target = $Repository
            IsLocal = $false
        }
    }

    $resolvedModuleDirectoryPath = Resolve-NovaLocalPublishPath -ModuleDirectoryPath $ModuleDirectoryPath
    $publishParameters.ModuleDirectoryPath = $resolvedModuleDirectoryPath

    return [pscustomobject]@{
        Action = (Get-Command -Name Publish-NovaBuiltModuleToDirectory -CommandType Function).ScriptBlock
        Parameters = $publishParameters
        Target = $resolvedModuleDirectoryPath
        IsLocal = $true
    }
}

