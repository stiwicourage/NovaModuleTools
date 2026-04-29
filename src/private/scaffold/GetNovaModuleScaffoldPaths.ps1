function Get-NovaModuleScaffoldLayout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$ProjectName
    )

    $dirProject = Join-Path -Path $Path -ChildPath $ProjectName
    $dirSrc = Join-Path -Path $dirProject -ChildPath 'src'

    return [pscustomobject]@{
        Project = $dirProject
        Src = $dirSrc
        Private = Join-Path -Path $dirSrc -ChildPath 'private'
        Public = Join-Path -Path $dirSrc -ChildPath 'public'
        Resources = Join-Path -Path $dirSrc -ChildPath 'resources'
        Classes = Join-Path -Path $dirSrc -ChildPath 'classes'
        Tests = Join-Path -Path $dirProject -ChildPath 'tests'
        ProjectJsonFile = Join-Path -Path $dirProject -ChildPath 'project.json'
    }
}
