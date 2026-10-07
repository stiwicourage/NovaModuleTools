function Update-ManifestPrivateData {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][System.Collections.IDictionary]$PrivateData
    )

    if ($PrivateData.Contains('PSData')) {
        Stop-NovaOperation -Message "Manifest.PrivateData cannot contain the reserved key 'PSData'. Nova preserves PowerShell-generated PSData separately." -ErrorId 'Nova.Configuration.ManifestPrivateDataReservedKey' -Category InvalidData -TargetObject 'Manifest.PrivateData.PSData'
    }

    $manifest = Import-PowerShellDataFile -LiteralPath $ManifestPath -ErrorAction Stop
    $mergedPrivateData = Get-MergedManifestPrivateData -Manifest $manifest -PrivateData $PrivateData
    $replacementBlock = "PrivateData = $( ConvertTo-PowerShellDataLiteral -Value $mergedPrivateData )"
    $updatedContent = Get-ManifestContentWithUpdatedHashtableEntryValue -ManifestPath $ManifestPath -Name 'PrivateData' -ReplacementValue $replacementBlock

    Set-Content -LiteralPath $ManifestPath -Value $updatedContent -NoNewline
}

function Get-MergedManifestPrivateData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][System.Collections.IDictionary]$PrivateData
    )

    $mergedPrivateData = [ordered]@{}
    $generatedPsData = Get-GeneratedManifestPsData -Manifest $Manifest
    if ($null -ne $generatedPsData) {
        $mergedPrivateData['PSData'] = $generatedPsData
    }

    foreach ($key in (Get-PowerShellDataDictionaryKeyList -Dictionary $PrivateData)) {
        $mergedPrivateData[$key] = $PrivateData[$key]
    }

    return $mergedPrivateData
}

function Get-GeneratedManifestPsData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest
    )

    $privateData = $Manifest.PrivateData
    if ($privateData -is [System.Collections.IDictionary]) {
        return Get-ManifestPsDataDictionary -PSData $privateData['PSData']
    }

    if ($null -eq $privateData) {
        return $null
    }

    return Get-ManifestPsDataDictionary -PSData $privateData.PSData
}

function Get-ManifestPsDataDictionary {
    [CmdletBinding()]
    param(
        [AllowNull()]$PSData
    )

    if ($null -eq $PSData) {
        return $null
    }

    if ($PSData -is [System.Collections.IDictionary]) {
        return [ordered]@{} + $PSData
    }

    $dictionary = [ordered]@{}
    foreach ($property in $PSData.PSObject.Properties) {
        $dictionary[$property.Name] = $property.Value
    }

    return $dictionary
}

function Get-ManifestContentWithUpdatedHashtableEntryValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ReplacementValue
    )

    $content = Get-Content -LiteralPath $ManifestPath -Raw
    $pair = Get-ManifestHashtableEntryAst -ManifestPath $ManifestPath -Name $Name
    $keyStart = $pair.Item1.Extent.StartOffset
    $valueEnd = $pair.Item2.Extent.EndOffset

    return "$( $content.Substring(0, $keyStart) )$ReplacementValue$( $content.Substring($valueEnd) )"
}

function Get-ManifestHashtableEntryAst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath,
        [Parameter(Mandatory)][string]$Name
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ManifestPath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        Stop-NovaOperation -Message "Failed to parse generated manifest before updating PrivateData: $ManifestPath" -ErrorId 'Nova.Dependency.ModuleManifestParsingFailed' -Category ParserError -TargetObject $ManifestPath
    }

    $topLevelHashtable = Get-TopLevelManifestHashtableAst -Ast $ast
    $pair = @(
        $topLevelHashtable.KeyValuePairs |
            Where-Object {$_.Item1.SafeGetValue() -eq $Name} |
            Select-Object -First 1
    )[0]
    if ($null -eq $pair) {
        Stop-NovaOperation -Message "Generated manifest is missing the top-level $Name entry: $ManifestPath" -ErrorId 'Nova.Dependency.ModuleManifestPrivateDataMissing' -Category InvalidData -TargetObject $ManifestPath
    }

    return $pair
}

function Get-TopLevelManifestHashtableAst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.Language.ScriptBlockAst]$Ast
    )

    $hashtableList = @(
        $Ast.FindAll(
            { param($node) $node -is [System.Management.Automation.Language.HashtableAst] },
            $true
        ) |
            Sort-Object {
                $_.Extent.EndOffset - $_.Extent.StartOffset
            } -Descending
    )
    if ($hashtableList.Count -eq 0) {
        Stop-NovaOperation -Message 'Generated manifest does not contain a top-level hashtable.' -ErrorId 'Nova.Dependency.ModuleManifestParsingFailed' -Category InvalidData -TargetObject $Ast.Extent.File
    }

    return $hashtableList[0]
}
