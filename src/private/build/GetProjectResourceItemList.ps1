function Get-ProjectResourceItemList {
    param(
        [Parameter(Mandatory)][string]$ResourceFolder
    )

    return @(
        Get-ChildItem -Path $ResourceFolder -ErrorAction SilentlyContinue
    )
}
