function New-NovaPackageContentTypesXml {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only returns XML text and does not mutate external state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject[]]$FileEntries
    )

    $defaultMap = [ordered]@{
        rels = 'application/vnd.openxmlformats-package.relationships+xml'
        psmdcp = 'application/vnd.openxmlformats-package.core-properties+xml'
        nuspec = 'application/octet'
    }
    $overridePartList = [System.Collections.Generic.List[string]]::new()

    foreach ($fileEntry in $FileEntries) {
        $extension = [System.IO.Path]::GetExtension($fileEntry.PackagePath)
        if ( [string]::IsNullOrWhiteSpace($extension)) {
            $overridePartList.Add("/$( $fileEntry.PackagePath )")
            continue
        }

        $defaultMap[$extension.TrimStart('.').ToLowerInvariant()] = 'application/octet'
    }

    $xmlLines = @(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    )

    foreach ($extension in $defaultMap.Keys) {
        $xmlLines += '  <Default Extension="{0}" ContentType="{1}" />' -f $extension, $defaultMap[$extension]
    }

    foreach ($partName in $overridePartList | Sort-Object -Unique) {
        $xmlLines += '  <Override PartName="{0}" ContentType="application/octet" />' -f $partName
    }

    $xmlLines += '</Types>'
    return $xmlLines -join [Environment]::NewLine
}

