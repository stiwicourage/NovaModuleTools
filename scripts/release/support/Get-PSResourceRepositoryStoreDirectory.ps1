function Get-PSResourceRepositoryStoreDirectory {
    [CmdletBinding()]
    param()

    return Join-Path $HOME '.local/share/PSResourceGet'
}

