function Get-NovaModuleProjectTemplatePath {
    [CmdletBinding()]
    param(
        [switch]$Example
    )

    $fileName = if ($Example) {
        [System.IO.Path]::Combine('example', 'project.json')
    }
    else {
        'ProjectTemplate.json'
    }

    return Get-ResourceFilePath -FileName $fileName
}
