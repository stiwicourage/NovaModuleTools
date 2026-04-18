function Write-NovaModuleProjectJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][string]$ProjectJsonFile,
        [switch]$Example
    )

    $jsonData = Get-Content (Get-NovaModuleProjectTemplatePath -Example:$Example) -Raw | ConvertFrom-Json -AsHashtable

    $jsonData.ProjectName = $Answer.ProjectName
    $jsonData.Description = $Answer.Description
    $jsonData.Version = $Answer.Version
    $jsonData.Manifest.Author = $Answer.Author
    $jsonData.Manifest.PowerShellHostVersion = $Answer.PowerShellHostVersion
    if (-not $Example) {
        $jsonData.Manifest.GUID = (New-Guid).GUID
    }

    if (-not $Example -and $Answer.EnablePester -eq 'No') {
        $jsonData.Remove('Pester')
    }

    Write-Verbose $jsonData
    $jsonData | ConvertTo-Json -Depth 10 | Out-File $ProjectJsonFile
}
