function ConvertTo-CoberturaRelativePath {
    param([string]$Path)

    return ($Path -replace '\\', '/')
}

function Get-CodeSceneCoverageErrorRecord {
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter(Mandatory)][string]$ErrorId,
        [Parameter(Mandatory)][System.Management.Automation.ErrorCategory]$Category,
        [AllowNull()]$TargetObject
    )

    return [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($Message),
            $ErrorId,
            $Category,
            $TargetObject
    )
}

function Get-SourceSectionListFromBuiltModule {
    param(
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $sourceMarkers = Select-String -Path $BuiltModulePath -Pattern '^# Source:\s+(.+)$'
    if (@($sourceMarkers).Count -eq 0) {
        throw (Get-CodeSceneCoverageErrorRecord -Message "Could not find any '# Source:' markers in built module: $BuiltModulePath" -ErrorId 'Nova.Coverage.BuiltModuleSourceMarkersMissing' -Category ObjectNotFound -TargetObject $BuiltModulePath)
    }

    $sections = foreach ($sourceMarker in $sourceMarkers) {
        $relativePath = ConvertTo-CoberturaRelativePath $sourceMarker.Matches[0].Groups[1].Value.Trim()
        $sourcePath = Join-Path $RepoRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw (Get-CodeSceneCoverageErrorRecord -Message "Source file referenced by built module was not found: $sourcePath" -ErrorId 'Nova.Coverage.BuiltModuleSourceFileNotFound' -Category ObjectNotFound -TargetObject $sourcePath)
        }

        $sourceLineCount = @(Get-Content -LiteralPath $sourcePath).Count
        [pscustomobject]@{
            RelativePath = $relativePath
            MarkerLine = $sourceMarker.LineNumber
            StartLine = $sourceMarker.LineNumber + 1
            EndLine = $sourceMarker.LineNumber + $sourceLineCount
        }
    }

    return @($sections)
}

function Find-SourceSectionForLine {
    param(
        [Parameter(Mandatory)][object[]]$Sections,
        [Parameter(Mandatory)][int]$LineNumber
    )

    foreach ($section in $Sections) {
        if ($LineNumber -ge $section.StartLine -and $LineNumber -le $section.EndLine) {
            return $section
        }
    }

    return $null
}

function Get-EmptyCoberturaLineBucket {
    return @{}
}

function Add-CoberturaLineHit {
    param(
        [Parameter(Mandatory)][hashtable]$Bucket,
        [Parameter(Mandatory)][int]$LineNumber,
        [Parameter(Mandatory)][int]$Hits
    )

    if ( $Bucket.ContainsKey($LineNumber)) {
        $Bucket[$LineNumber] = [Math]::Max([int]$Bucket[$LineNumber], $Hits)
        return
    }

    $Bucket[$LineNumber] = $Hits
}

function Get-CoberturaLineStat {
    param([Parameter(Mandatory)][hashtable]$Bucket)

    $validLineCount = @($Bucket.Keys).Count
    $coveredLineCount = @($Bucket.Values | Where-Object {$_ -gt 0}).Count
    $lineRate = if ($validLineCount -eq 0) {
        0
    }
    else {
        $coveredLineCount / $validLineCount
    }

    return [pscustomobject]@{
        ValidLineCount = $validLineCount
        CoveredLineCount = $coveredLineCount
        LineRate = $lineRate
    }
}

function Get-CoberturaPackageName {
    param([string]$RelativePath)

    $parentPath = Split-Path -Parent $RelativePath
    if ( [string]::IsNullOrWhiteSpace($parentPath)) {
        return ''
    }

    return (ConvertTo-CoberturaRelativePath $parentPath)
}

function Get-CoberturaSourceLineRange {
    param([Parameter(Mandatory)][object[]]$Sections)

    return [pscustomobject]@{
        FirstSourceLine = ($Sections | Measure-Object -Property StartLine -Minimum).Minimum
        LastSourceLine = ($Sections | Measure-Object -Property EndLine -Maximum).Maximum
    }
}

function Test-CoberturaLineOutsideSourceRange {
    param(
        [Parameter(Mandatory)][pscustomobject]$LineRange,
        [Parameter(Mandatory)][int]$LineNumber
    )

    return $LineNumber -lt $LineRange.FirstSourceLine -or $LineNumber -gt $LineRange.LastSourceLine
}

function Add-CoberturaMappedLineHit {
    param(
        [Parameter(Mandatory)][hashtable]$LineBucketsByFile,
        [Parameter(Mandatory)][pscustomobject]$SourceSection,
        [Parameter(Mandatory)][int]$BuiltLineNumber,
        [Parameter(Mandatory)][int]$Hits
    )

    if (-not $LineBucketsByFile.ContainsKey($SourceSection.RelativePath)) {
        $LineBucketsByFile[$SourceSection.RelativePath] = Get-EmptyCoberturaLineBucket
    }

    $sourceLineNumber = $BuiltLineNumber - $SourceSection.MarkerLine
    Add-CoberturaLineHit -Bucket $LineBucketsByFile[$SourceSection.RelativePath] -LineNumber $sourceLineNumber -Hits $Hits
}

function Add-CoberturaLineNodeHit {
    param(
        [Parameter(Mandatory)][System.Xml.XmlNode]$LineNode,
        [Parameter(Mandatory)][object[]]$SourceSections,
        [Parameter(Mandatory)][pscustomobject]$SourceLineRange,
        [Parameter(Mandatory)][hashtable]$LineBucketsByFile
    )

    $builtLineNumber = [int]$LineNode.number
    $sourceSection = Find-SourceSectionForLine -Sections $SourceSections -LineNumber $builtLineNumber
    if ($null -eq $sourceSection) {
        if (Test-CoberturaLineOutsideSourceRange -LineRange $SourceLineRange -LineNumber $builtLineNumber) {
            return $null
        }

        return $builtLineNumber
    }

    Add-CoberturaMappedLineHit -LineBucketsByFile $LineBucketsByFile -SourceSection $sourceSection -BuiltLineNumber $builtLineNumber -Hits ([int]$LineNode.hits)
    return $null
}

function Get-CoberturaLineBucketMap {
    param(
        [Parameter(Mandatory)][string]$CoveragePath,
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    [xml]$originalCoverageXml = Get-Content -LiteralPath $CoveragePath -Raw
    $originalCoverageNode = $originalCoverageXml.SelectSingleNode('/coverage')
    if ($null -eq $originalCoverageNode) {
        throw (Get-CodeSceneCoverageErrorRecord -Message "No Cobertura coverage root node was found in coverage file: $CoveragePath" -ErrorId 'Nova.Coverage.CoberturaRootNodeNotFound' -Category InvalidData -TargetObject $CoveragePath)
    }

    $sourceSections = Get-SourceSectionListFromBuiltModule -BuiltModulePath $BuiltModulePath -RepoRoot $RepoRoot
    $classNodes = @($originalCoverageXml.SelectNodes('/coverage/packages/package/classes/class'))
    if (@($classNodes).Count -eq 0) {
        throw (Get-CodeSceneCoverageErrorRecord -Message "No Cobertura class nodes were found in coverage file: $CoveragePath" -ErrorId 'Nova.Coverage.CoberturaClassNodesNotFound' -Category InvalidData -TargetObject $CoveragePath)
    }

    $sourceLineRange = Get-CoberturaSourceLineRange -Sections $sourceSections

    $lineBucketsByFile = @{}
    $unmappedLineNumbers = @()
    foreach ($classNode in $classNodes) {
        foreach ($lineNode in @($classNode.lines.line)) {
            $unmappedLineNumber = Add-CoberturaLineNodeHit -LineNode $lineNode -SourceSections $sourceSections -SourceLineRange $sourceLineRange -LineBucketsByFile $lineBucketsByFile
            if ($null -ne $unmappedLineNumber) {
                $unmappedLineNumbers += $unmappedLineNumber
            }
        }
    }

    if (@($unmappedLineNumbers).Count -gt 0) {
        $preview = ($unmappedLineNumbers | Sort-Object -Unique | Select-Object -First 10) -join ', '
        throw (Get-CodeSceneCoverageErrorRecord -Message "Could not map one or more covered built-module lines back to source files. Example line numbers: $preview" -ErrorId 'Nova.Coverage.CoberturaLineMappingFailed' -Category InvalidData -TargetObject $preview)
    }

    return [pscustomobject]@{
        OriginalCoverageNode = $originalCoverageNode
        LineBucketMap = $lineBucketsByFile
    }
}
