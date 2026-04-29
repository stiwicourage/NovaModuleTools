function Add-CoberturaAttribute {
    param(
        [Parameter(Mandatory)][System.Xml.XmlElement]$Element,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $attribute = $Element.OwnerDocument.CreateAttribute($Name)
    $attribute.Value = $Value
    $null = $Element.Attributes.Append($attribute)
}

function Get-CoberturaClassElement {
    param(
        [Parameter(Mandatory)][System.Xml.XmlDocument]$Document,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][hashtable]$LineBucket
    )

    $lineStat = Get-CoberturaLineStat -Bucket $LineBucket
    $classNode = $Document.CreateElement('class')
    Add-CoberturaAttribute -Element $classNode -Name 'name' -Value (Split-Path -Leaf $RelativePath)
    Add-CoberturaAttribute -Element $classNode -Name 'filename' -Value $RelativePath
    Add-CoberturaAttribute -Element $classNode -Name 'line-rate' -Value ([string]$lineStat.LineRate)
    Add-CoberturaAttribute -Element $classNode -Name 'branch-rate' -Value '1'

    $methodsNode = $Document.CreateElement('methods')
    $null = $classNode.AppendChild($methodsNode)

    $linesNode = $Document.CreateElement('lines')
    foreach ($lineNumber in @($LineBucket.Keys | Sort-Object)) {
        $lineNode = $Document.CreateElement('line')
        Add-CoberturaAttribute -Element $lineNode -Name 'number' -Value ([string]$lineNumber)
        Add-CoberturaAttribute -Element $lineNode -Name 'hits' -Value ([string]$LineBucket[$lineNumber])
        $null = $linesNode.AppendChild($lineNode)
    }

    $null = $classNode.AppendChild($linesNode)

    return [pscustomobject]@{
        ClassNode = $classNode
        LineStat = $lineStat
    }
}

function Get-CoberturaPackageElement {
    param(
        [Parameter(Mandatory)][System.Xml.XmlDocument]$Document,
        [Parameter(Mandatory)][string]$PackageName,
        [Parameter(Mandatory)][hashtable]$LineBucketMap
    )

    $packageNode = $Document.CreateElement('package')
    Add-CoberturaAttribute -Element $packageNode -Name 'name' -Value $PackageName
    Add-CoberturaAttribute -Element $packageNode -Name 'branch-rate' -Value '0'

    $classesNode = $Document.CreateElement('classes')
    $null = $packageNode.AppendChild($classesNode)

    $packageValidLineCount = 0
    $packageCoveredLineCount = 0
    $packageFilePaths = @(
    $LineBucketMap.Keys |
            Where-Object {(Get-CoberturaPackageName -RelativePath $_) -eq $PackageName} |
            Sort-Object
    )

    foreach ($relativePath in $packageFilePaths) {
        $classResult = Get-CoberturaClassElement -Document $Document -RelativePath $relativePath -LineBucket $LineBucketMap[$relativePath]
        $null = $classesNode.AppendChild($classResult.ClassNode)
        $packageValidLineCount += $classResult.LineStat.ValidLineCount
        $packageCoveredLineCount += $classResult.LineStat.CoveredLineCount
    }

    $packageLineRate = if ($packageValidLineCount -eq 0) {
        0
    }
    else {
        $packageCoveredLineCount / $packageValidLineCount
    }

    Add-CoberturaAttribute -Element $packageNode -Name 'line-rate' -Value ([string]$packageLineRate)

    return [pscustomobject]@{
        PackageNode = $packageNode
        ValidLineCount = $packageValidLineCount
        CoveredLineCount = $packageCoveredLineCount
    }
}

function Get-CoberturaCoverageAttributeMap {
    param(
        [Parameter(Mandatory)][int]$ValidLineCount,
        [Parameter(Mandatory)][int]$CoveredLineCount,
        [Parameter(Mandatory)][System.Xml.XmlElement]$OriginalCoverageNode
    )

    $lineRate = if ($ValidLineCount -eq 0) {
        0
    }
    else {
        $CoveredLineCount / $ValidLineCount
    }

    return [ordered]@{
        'lines-valid' = [string]$ValidLineCount
        'lines-covered' = [string]$CoveredLineCount
        'line-rate' = [string]$lineRate
        'branches-valid' = '0'
        'branches-covered' = '0'
        'branch-rate' = '1'
        'timestamp' = [string]$OriginalCoverageNode.GetAttribute('timestamp')
        'version' = [string]$OriginalCoverageNode.GetAttribute('version')
    }
}

function Get-CoberturaCoverageDocument {
    param(
        [Parameter(Mandatory)][hashtable]$LineBucketMap,
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][System.Xml.XmlElement]$OriginalCoverageNode
    )

    $newCoverageXml = New-Object System.Xml.XmlDocument
    $declaration = $newCoverageXml.CreateXmlDeclaration('1.0', 'utf-8', $null)
    $null = $newCoverageXml.AppendChild($declaration)

    $coverageNode = $newCoverageXml.CreateElement('coverage')
    $null = $newCoverageXml.AppendChild($coverageNode)

    $sourcesNode = $newCoverageXml.CreateElement('sources')
    $sourceNode = $newCoverageXml.CreateElement('source')
    $sourceNode.InnerText = ConvertTo-CoberturaRelativePath $RepoRoot
    $null = $sourcesNode.AppendChild($sourceNode)
    $null = $coverageNode.AppendChild($sourcesNode)

    $packagesNode = $newCoverageXml.CreateElement('packages')
    $null = $coverageNode.AppendChild($packagesNode)

    $packageNames = @(
    $LineBucketMap.Keys |
            ForEach-Object {Get-CoberturaPackageName -RelativePath $_} |
            Sort-Object -Unique
    )

    $totalValidLineCount = 0
    $totalCoveredLineCount = 0
    foreach ($packageName in $packageNames) {
        $packageResult = Get-CoberturaPackageElement -Document $newCoverageXml -PackageName $packageName -LineBucketMap $LineBucketMap
        $null = $packagesNode.AppendChild($packageResult.PackageNode)
        $totalValidLineCount += $packageResult.ValidLineCount
        $totalCoveredLineCount += $packageResult.CoveredLineCount
    }

    $coverageAttributeMap = Get-CoberturaCoverageAttributeMap -ValidLineCount $totalValidLineCount -CoveredLineCount $totalCoveredLineCount -OriginalCoverageNode $OriginalCoverageNode
    foreach ($attributeName in $coverageAttributeMap.Keys) {
        Add-CoberturaAttribute -Element $coverageNode -Name $attributeName -Value $coverageAttributeMap[$attributeName]
    }

    return $newCoverageXml
}

function Convert-CoberturaCoverageToSourcePath {
    param(
        [Parameter(Mandatory)][string]$CoveragePath,
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $bucketResult = Get-CoberturaLineBucketMap -CoveragePath $CoveragePath -BuiltModulePath $BuiltModulePath -RepoRoot $RepoRoot
    $newCoverageXml = Get-CoberturaCoverageDocument -LineBucketMap $bucketResult.LineBucketMap -RepoRoot $RepoRoot -OriginalCoverageNode $bucketResult.OriginalCoverageNode

    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.Encoding = [System.Text.UTF8Encoding]::new($false)
    $xmlWriter = [System.Xml.XmlWriter]::Create($CoveragePath, $xmlWriterSettings)
    try {
        $newCoverageXml.Save($xmlWriter)
    }
    finally {
        $xmlWriter.Dispose()
    }
}
