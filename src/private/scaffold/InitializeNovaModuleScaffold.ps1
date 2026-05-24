function Initialize-NovaModuleScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][pscustomobject]$Paths,
        [switch]$Example
    )

    if (Test-Path -LiteralPath $Paths.Project) {
        Stop-NovaOperation -Message "Project folder already exists: $( $Paths.Project ). Choose a different project name or remove or move the existing folder before running Initialize-NovaModule again." -ErrorId 'Nova.Workflow.ScaffoldProjectAlreadyExists' -Category ResourceExists -TargetObject $Paths.Project
    }

    Write-Message 'Starting Nova module scaffold' -color Green
    Write-Message 'Creating project directories'

    if ($Example) {
        Initialize-NovaExampleModuleScaffold -Paths $Paths
    } else {
        Initialize-NovaDefaultModuleScaffold -Answer $Answer -Paths $Paths
    }

    if ($Answer.EnableGit -eq 'Yes') {
        Update-NovaGitIgnore -ProjectRoot $Paths.Project -Confirm:$false
        Write-Message 'Initializing Git repository'
        New-InitiateGitRepo -DirectoryPath $Paths.Project
    }
}

function Initialize-NovaDefaultModuleScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][pscustomobject]$Paths
    )

    foreach ($directory in @($Paths.Project, $Paths.Src, $Paths.Private, $Paths.Public, $Paths.Resources, $Paths.Classes)) {
        'Creating Directory: {0}' -f $directory | Write-Verbose
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    if ($Answer.EnablePester -eq 'Yes') {
        Write-Message 'Creating tests folder'
        New-Item -ItemType Directory -Path $Paths.Tests | Out-Null
    }
}

function Initialize-NovaExampleModuleScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Paths
    )

    Write-Message 'Copying packaged example project'
    New-Item -ItemType Directory -Path $Paths.Project | Out-Null
    Copy-NovaExampleProjectTemplate -DestinationPath $Paths.Project
}
