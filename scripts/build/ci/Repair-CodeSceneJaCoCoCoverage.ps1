param(
    [Parameter(Mandatory)][string[]]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Repair-CodeSceneJaCoCoNodePathAttribute {
    param(
        [Parameter(Mandatory)]$Nodes,
        [Parameter(Mandatory)][string]$AttributeName
    )

    $changed = $false
    foreach ($node in $Nodes) {
        $changed = (Repair-CodeSceneJaCoCoNodeFileName -Node $node -AttributeName $AttributeName) -or $changed
    }

    return $changed
}

function Repair-CodeSceneJaCoCoNodeFileName {
    param(
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][string]$AttributeName
    )

    $original = $Node.GetAttribute($AttributeName)
    $normalized = [System.IO.Path]::GetFileName($original)
    if ($normalized -eq $original) {
        return $false
    }

    $Node.SetAttribute($AttributeName, $normalized)
    return $true
}

function Repair-CodeSceneJaCoCoCoverageFile {
    param([Parameter(Mandatory)][string]$Path)

    [xml]$document = Get-Content -LiteralPath $Path -Raw
    $changed = Repair-CodeSceneJaCoCoNodePathAttribute -Nodes $document.SelectNodes('//class[@sourcefilename]') -AttributeName 'sourcefilename'
    $changed = (Repair-CodeSceneJaCoCoNodePathAttribute -Nodes $document.SelectNodes('//sourcefile[@name]') -AttributeName 'name') -or $changed

    if ($changed) {
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Encoding = New-Object System.Text.UTF8Encoding($false)
        $settings.Indent = $false
        $settings.NewLineHandling = [System.Xml.NewLineHandling]::None
        $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
        try {
            $document.Save($writer)
        } finally {
            $writer.Dispose()
        }

        Write-Host "Normalized JaCoCo sourcefile paths in '$Path' so package + sourcefile resolve to repo files."
    }
}

foreach ($item in $Path) {
    $resolvedPath = (Resolve-Path -LiteralPath $item -ErrorAction Stop).Path
    Repair-CodeSceneJaCoCoCoverageFile -Path $resolvedPath
}
