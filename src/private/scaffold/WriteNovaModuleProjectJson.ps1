function Write-NovaModuleProjectJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][string]$ProjectJsonFile
    )

    $jsonData = Get-Content (Get-ResourceFilePath -FileName 'ProjectTemplate.json') -Raw | ConvertFrom-Json -AsHashtable

    $jsonData.ProjectName = $Answer.ProjectName
    $jsonData.Description = $Answer.Description
    $jsonData.Version = $Answer.Version
    $jsonData.Manifest.Author = $Answer.Author
    $jsonData.Manifest.PowerShellHostVersion = $Answer.PowerShellHostVersion
    $jsonData.Manifest.GUID = (New-Guid).GUID

    if ($Answer.EnablePester -eq 'No') {
        $jsonData.Remove('Pester')
    }

    Write-Verbose $jsonData
    $jsonData | ConvertTo-Json | Out-File $ProjectJsonFile
}

