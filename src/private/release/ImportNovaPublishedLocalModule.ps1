function Import-NovaPublishedLocalModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ManifestPath
    )

    if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
        throw "Expected locally published module manifest at: $ManifestPath"
    }

    $loadedModules = @(Get-Module -Name $ProjectName -All)
    $loadedModules | Where-Object Path -EQ $ManifestPath | Remove-Module -Force -ErrorAction SilentlyContinue

    $importedModule = Import-Module -Name $ManifestPath -Force -Global -PassThru -ErrorAction Stop
    $loadedModules |
            Where-Object {$_.Path -and $_.Path -ne $importedModule.Path} |
            Remove-Module -Force -ErrorAction SilentlyContinue

    return $importedModule
}
