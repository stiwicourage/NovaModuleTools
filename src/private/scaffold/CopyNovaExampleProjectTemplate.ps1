function Copy-NovaExampleProjectTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestinationPath
    )

    $templateRoot = Split-Path -Parent (Get-NovaModuleProjectTemplatePath -Example)
    $templateItemList = @(Get-ChildItem -LiteralPath $templateRoot -Force)

    foreach ($item in $templateItemList) {
        Copy-Item -LiteralPath $item.FullName -Destination $DestinationPath -Recurse -Force -ErrorAction Stop
    }
}
