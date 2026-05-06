function Build-Help {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )
    Write-Verbose 'Running Help update'

    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo
    $helpMarkdownFiles = @(Get-NovaHelpMarkdownItem -BuildProjectInfo $data)

    if (-not $helpMarkdownFiles) {
        return
    }

    Assert-NovaPlatyPSAvailable

    $helpContext = Get-NovaHelpBuildContext -BuildProjectInfo $data -HelpMarkdownFiles $helpMarkdownFiles
    if (-not $helpContext) {
        return
    }

    Export-NovaGeneratedHelp -BuildProjectInfo $data -HelpContext $helpContext
}

function Get-NovaHelpMarkdownItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$BuildProjectInfo
    )

    $helpDocsDir = Get-NovaHelpDocsDir -BuildProjectInfo $BuildProjectInfo
    $helpMarkdownFiles = @(Get-ChildItem -LiteralPath $helpDocsDir -Filter '*.md' -File -Recurse -ErrorAction SilentlyContinue)
    if (-not $helpMarkdownFiles) {
        Write-Verbose "No help markdown files in $helpDocsDir, skipping building help"
    }

    return $helpMarkdownFiles
}

function Get-NovaHelpBuildContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$BuildProjectInfo,
        [Parameter(Mandatory)][System.IO.FileInfo[]]$HelpMarkdownFiles
    )

    $commandHelpFiles = @($HelpMarkdownFiles | Measure-PlatyPSMarkdown | Where-Object FileType -Match CommandHelp)
    if (-not $commandHelpFiles) {
        Write-Verbose "No PlatyPS command help markdown files found in $( Get-NovaHelpDocsDir -BuildProjectInfo $BuildProjectInfo ), skipping building help"
        return $null
    }

    return [pscustomobject]@{
        HelpMarkdownFiles = $HelpMarkdownFiles
        CommandHelpFiles = $commandHelpFiles
        Locale = Get-NovaHelpLocale -HelpMarkdownFiles $HelpMarkdownFiles
    }
}

function Export-NovaGeneratedHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$BuildProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$HelpContext
    )

    $HelpContext.CommandHelpFiles | Import-MarkdownCommandHelp -Path {$_.FilePath} |
            Export-MamlCommandHelp -OutputFolder $BuildProjectInfo.OutputModuleDir | Out-Null

    Rename-NovaGeneratedHelpFolder -BuildProjectInfo $BuildProjectInfo -Locale $HelpContext.Locale
}

function Rename-NovaGeneratedHelpFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$BuildProjectInfo,
        [Parameter(Mandatory)][string]$Locale
    )

    $helpDirOld = Join-Path $BuildProjectInfo.OutputModuleDir $BuildProjectInfo.ProjectName
    if (-not (Test-Path -LiteralPath $helpDirOld)) {
        $helpDocsDir = Get-NovaHelpDocsDir -BuildProjectInfo $BuildProjectInfo
        Stop-NovaOperation -Message "Expected generated help directory was not created: $helpDirOld. Verify that the Markdown files under '$helpDocsDir' are valid PlatyPS command help." -ErrorId 'Nova.Environment.GeneratedHelpDirectoryNotFound' -Category ObjectNotFound -TargetObject $helpDirOld
    }

    $helpDirNew = Join-Path $BuildProjectInfo.OutputModuleDir $Locale
    Write-Verbose "Renamed folder to locale: $Locale"
    Rename-Item -Path $helpDirOld -NewName $helpDirNew
}

function Get-NovaHelpDocsDir {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$BuildProjectInfo
    )

    return [System.IO.Path]::Join($BuildProjectInfo.DocsDir, $BuildProjectInfo.ProjectName)
}

function Assert-NovaPlatyPSAvailable {
    [CmdletBinding()]
    param()

    if (-not (Get-Module -Name Microsoft.PowerShell.PlatyPS -ListAvailable)) {
        Stop-NovaOperation -Message 'The module Microsoft.PowerShell.PlatyPS must be installed for Markdown documentation to be generated.' -ErrorId 'Nova.Dependency.BuildHelpDependencyMissing' -Category ResourceUnavailable -TargetObject 'Microsoft.PowerShell.PlatyPS'
    }
}
