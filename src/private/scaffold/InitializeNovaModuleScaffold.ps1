function Initialize-NovaModuleScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][pscustomobject]$Paths
    )

    if (Test-Path $Paths.Project) {
        throw 'Project already exists, aborting'
    }

    Write-Message "`nStarted Module Scaffolding" -color Green
    Write-Message 'Setting up Directories'

    foreach ($directory in @($Paths.Project, $Paths.Src, $Paths.Private, $Paths.Public, $Paths.Resources, $Paths.Classes)) {
        'Creating Directory: {0}' -f $directory | Write-Verbose
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    if ($Answer.EnablePester -eq 'Yes') {
        Write-Message 'Include Pester Configs'
        New-Item -ItemType Directory -Path $Paths.Tests | Out-Null
    }

    if ($Answer.EnableGit -eq 'Yes') {
        Write-Message 'Initialize Git Repo'
        New-InitiateGitRepo -DirectoryPath $Paths.Project
    }
}

