function Invoke-NovaRelease {
    [CmdletBinding()]
    param(
        [hashtable]$PublishOption = @{},
        [string]$Path = (Get-Location).Path
    )

    Push-Location -LiteralPath $Path
    try {
        if ($PublishOption.Local) {
            Write-Verbose 'Using local release mode.'
        }

        Invoke-NovaBuild
        Test-NovaBuild
        $versionResult = Update-NovaModuleVersion
        Invoke-NovaBuild

        if ( $PublishOption.ContainsKey('Repository')) {
            Publish-NovaBuiltModule -Repository $PublishOption.Repository -ApiKey $PublishOption.ApiKey
        }
        else {
            Publish-NovaBuiltModule -ModuleDirectoryPath $PublishOption.ModuleDirectoryPath
        }

        return $versionResult
    }
    finally {
        Pop-Location
    }
}



