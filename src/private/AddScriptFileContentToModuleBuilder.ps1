function Add-ScriptFileContentToModuleBuilder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Text.StringBuilder]$Builder,
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][System.IO.FileInfo]$File
    )

    if ($ProjectInfo.SetSourcePath) {
        $relativePath = Get-NormalizedRelativePath -Root $ProjectInfo.ProjectRoot -FullName $File.FullName
        $Builder.AppendLine("# Source: $relativePath") | Out-Null
    }

    $Builder.AppendLine([IO.File]::ReadAllText($File.FullName)) | Out-Null
    $Builder.AppendLine() | Out-Null
}
