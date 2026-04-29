function Get-NovaModuleUpdateLookupScript {
    [CmdletBinding()]
    param()

    $lookupScriptPath = Get-ResourceFilePath -FileName 'update/ModuleUpdateLookup.ps1.txt'
    return Get-Content -LiteralPath $lookupScriptPath -Raw -ErrorAction Stop
}
