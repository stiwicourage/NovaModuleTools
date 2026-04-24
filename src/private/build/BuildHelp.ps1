function Build-Help {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )
    Write-Verbose 'Running Help update'

    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo
    $helpMarkdownFiles = Get-ChildItem -Path $data.DocsDir -Filter '*.md' -Recurse

    if (-not $helpMarkdownFiles) {
        Write-Verbose 'No help markdown files in docs directory, skipping building help' 
        return
    }
    
    if (-not (Get-Module -Name Microsoft.PowerShell.PlatyPS -ListAvailable)) {
        Stop-NovaOperation -Message 'The module Microsoft.PowerShell.PlatyPS must be installed for Markdown documentation to be generated.' -ErrorId 'Nova.Dependency.BuildHelpDependencyMissing' -Category ResourceUnavailable -TargetObject 'Microsoft.PowerShell.PlatyPS'
    }

    $AllCommandHelpFiles = $helpMarkdownFiles | Measure-PlatyPSMarkdown | Where-Object FileType -Match CommandHelp

    # Export to Dist folder    
    $AllCommandHelpFiles | Import-MarkdownCommandHelp -Path { $_.FilePath } |
    Export-MamlCommandHelp -OutputFolder $data.OutputModuleDir | Out-Null

    # Rename the directory to match locale
    $HelpDirOld = Join-Path $data.OutputModuleDir $Data.ProjectName
    $languageLocale = Get-NovaHelpLocale -HelpMarkdownFiles $helpMarkdownFiles
    $HelpDirNew = Join-Path $data.OutputModuleDir $languageLocale
    Write-Verbose "Renamed folder to locale: $languageLocale"

    Rename-Item -Path $HelpDirOld -NewName $HelpDirNew
}
