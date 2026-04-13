function Invoke-NovaRelease {
    [CmdletBinding()]
    param(
        [hashtable]$PublishOption = @{},
        [string]$Path = (Get-Location).Path
    )

    Push-Location -LiteralPath $Path
    try {
        $projectInfo = Get-NovaProjectInfo
        $publishParams = @{ProjectInfo = $projectInfo}
        $hasRepository = $PublishOption.ContainsKey('Repository')

        if ($hasRepository) {
            $publishAction = (Get-Command -Name Publish-NovaBuiltModuleToRepository -CommandType Function).ScriptBlock
            $publishParams.Repository = $PublishOption.Repository
            $publishParams.ApiKey = $PublishOption.ApiKey
        }
        else {
            $publishAction = (Get-Command -Name Publish-NovaBuiltModuleToDirectory -CommandType Function).ScriptBlock
            $resolvedModuleDirectoryPath = if ( $PublishOption.ContainsKey('ModuleDirectoryPath')) {
                $PublishOption.ModuleDirectoryPath
            }
            else {
                $null
            }

            if ( [string]::IsNullOrWhiteSpace($resolvedModuleDirectoryPath)) {
                $resolvedModuleDirectoryPath = Get-LocalModulePath
            }

            $publishParams.ModuleDirectoryPath = $resolvedModuleDirectoryPath
        }

        if ($PublishOption.ContainsKey('Local') -and $PublishOption.Local) {
            Write-Verbose 'Using local release mode.'
        }

        Invoke-NovaBuild
        Test-NovaBuild
        $versionResult = Update-NovaModuleVersion
        Invoke-NovaBuild

        & $publishAction @publishParams

        return $versionResult
    }
    finally {
        Pop-Location
    }
}



