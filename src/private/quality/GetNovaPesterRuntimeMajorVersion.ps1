function Get-NovaPesterRuntimeMajorVersion {
    [CmdletBinding()]
    param()

    $invokePesterCommand = Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue
    if ($null -ne $invokePesterCommand -and $null -ne $invokePesterCommand.Version) {
        return [int]$invokePesterCommand.Version.Major
    }

    $pesterModule = Get-Module -Name Pester -ListAvailable |
            Sort-Object Version -Descending |
            Select-Object -First 1
    if ($null -eq $pesterModule) {
        return $null
    }

    return [int]$pesterModule.Version.Major
}
