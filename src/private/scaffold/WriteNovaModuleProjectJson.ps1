function Write-NovaModuleProjectJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][string]$ProjectJsonFile,
        [switch]$Example
    )

    $projectTemplatePath = Get-NovaModuleProjectTemplatePath -Example:$Example
    $jsonData = Read-ProjectJsonData -ProjectJsonPath $projectTemplatePath

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
    Write-ProjectJsonData -ProjectJsonPath $ProjectJsonFile -Data $jsonData
}
