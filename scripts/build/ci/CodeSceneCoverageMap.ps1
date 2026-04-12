function ConvertTo-CoberturaRelativePath {
    param([string]$Path)

    return ($Path -replace '\\', '/')
}

function Get-SourceSectionListFromBuiltModule {
    param(
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    $sourceMarkers = Select-String -Path $BuiltModulePath -Pattern '^# Source:\s+(.+)$'
    if (@($sourceMarkers).Count -eq 0) {
        throw "Could not find any '# Source:' markers in built module: $BuiltModulePath"
    }

    $sections = foreach ($sourceMarker in $sourceMarkers) {
        $relativePath = ConvertTo-CoberturaRelativePath $sourceMarker.Matches[0].Groups[1].Value.Trim()
        $sourcePath = Join-Path $RepoRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Source file referenced by built module was not found: $sourcePath"
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

function Get-CoberturaLineBucketMap {
    param(
        [Parameter(Mandatory)][string]$CoveragePath,
        [Parameter(Mandatory)][string]$BuiltModulePath,
        [Parameter(Mandatory)][string]$RepoRoot
    )

    [xml]$originalCoverageXml = Get-Content -LiteralPath $CoveragePath -Raw
    $originalCoverageNode = $originalCoverageXml.SelectSingleNode('/coverage')
    if ($null -eq $originalCoverageNode) {
        throw "No Cobertura coverage root node was found in coverage file: $CoveragePath"
    }

    $sourceSections = Get-SourceSectionListFromBuiltModule -BuiltModulePath $BuiltModulePath -RepoRoot $RepoRoot
    $classNodes = @($originalCoverageXml.SelectNodes('/coverage/packages/package/classes/class'))
    if (@($classNodes).Count -eq 0) {
        throw "No Cobertura class nodes were found in coverage file: $CoveragePath"
    }

    $lineBucketsByFile = @{}
    $unmappedLineNumbers = @()
    foreach ($classNode in $classNodes) {
        foreach ($lineNode in @($classNode.lines.line)) {
            $builtLineNumber = [int]$lineNode.number
            $sourceSection = Find-SourceSectionForLine -Sections $sourceSections -LineNumber $builtLineNumber
            if ($null -eq $sourceSection) {
                $unmappedLineNumbers += $builtLineNumber
                continue
            }

            if (-not $lineBucketsByFile.ContainsKey($sourceSection.RelativePath)) {
                $lineBucketsByFile[$sourceSection.RelativePath] = Get-EmptyCoberturaLineBucket
            }

            $sourceLineNumber = $builtLineNumber - $sourceSection.MarkerLine
            Add-CoberturaLineHit -Bucket $lineBucketsByFile[$sourceSection.RelativePath] -LineNumber $sourceLineNumber -Hits ([int]$lineNode.hits)
        }
    }

    if (@($unmappedLineNumbers).Count -gt 0) {
        $preview = ($unmappedLineNumbers | Sort-Object -Unique | Select-Object -First 10) -join ', '
        throw "Could not map one or more covered built-module lines back to source files. Example line numbers: $preview"
    }

    return [pscustomobject]@{
        OriginalCoverageNode = $originalCoverageNode
        LineBucketMap = $lineBucketsByFile
    }
}


