function Write-ProjectJsonVersion {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Version
    )

    $project = Read-JsonFile -Path $Path
    $project.Version = $Version
    Write-JsonFile -Path $Path -Data $project
}
