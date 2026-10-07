function ConvertTo-PowerShellDataLiteral {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value,
        [int]$IndentLevel = 0
    )

    if ($null -eq $Value) {
        return '$null'
    }

    if ($Value -is [string]) {
        return ConvertTo-PowerShellQuotedStringLiteral -Value $Value
    }

    if ($Value -is [bool]) {
        if ($Value) {
            return '$true'
        }

        return '$false'
    }

    if (Test-PowerShellDataNumber -Value $Value) {
        return [System.Management.Automation.LanguagePrimitives]::ConvertTo($Value, [string], [System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return ConvertTo-PowerShellCollectionLiteral -Value $Value -IndentLevel $IndentLevel
    }

    if (Test-PowerShellDataList -Value $Value) {
        return ConvertTo-PowerShellCollectionLiteral -Value $Value -IndentLevel $IndentLevel
    }

    return ConvertTo-PowerShellQuotedStringLiteral -Value ([string]$Value)
}

function ConvertTo-PowerShellQuotedStringLiteral {
    [CmdletBinding()]
    param(
        [AllowEmptyString()]
        [Parameter(Mandatory)][string]$Value
    )

    return "'$( $Value -replace '''', '''''' )'"
}

function Test-PowerShellDataNumber {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value
    )

    if ($Value -isnot [ValueType]) {
        return $false
    }

    return @(
        'System.Byte'
        'System.SByte'
        'System.Int16'
        'System.UInt16'
        'System.Int32'
        'System.UInt32'
        'System.Int64'
        'System.UInt64'
        'System.Decimal'
        'System.Double'
        'System.Single'
    ) -contains $Value.GetType().FullName
}

function Test-PowerShellDataList {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value
    )

    return $Value -is [System.Collections.IList] -and $Value -isnot [string]
}

function ConvertTo-PowerShellCollectionLiteral {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Value,
        [int]$IndentLevel = 0
    )

    $blockMetadata = Get-PowerShellCollectionBlockDescriptor -Value $Value
    if ($null -ne $blockMetadata.EmptyLiteral) {
        return $blockMetadata.EmptyLiteral
    }

    return Format-PowerShellDataBlock `
        -OpeningToken $blockMetadata.OpeningToken `
        -ItemList (Get-PowerShellCollectionBlockItemList -Value $Value -IndentLevel $IndentLevel) `
        -IndentLevel $IndentLevel `
        -ClosingToken $blockMetadata.ClosingToken
}

function Get-PowerShellDataIndent {
    [CmdletBinding()]
    param(
        [int]$IndentLevel = 0
    )

    return (' ' * 4 * $IndentLevel)
}

function Format-PowerShellDataBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$OpeningToken,
        [Parameter(Mandatory)][string[]]$ItemList,
        [int]$IndentLevel = 0,
        [string]$ClosingToken = '}'
    )

    $joinedItems = $ItemList -join "`n"
    $closingIndent = Get-PowerShellDataIndent -IndentLevel $IndentLevel
    return "$OpeningToken`n$joinedItems`n$closingIndent$ClosingToken"
}

function Get-PowerShellCollectionBlockDescriptor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Value
    )

    if ($Value -is [System.Collections.IDictionary]) {
        return Get-PowerShellCollectionBlockDescriptorForCount -Count $Value.Count -EmptyLiteral '@{}' -OpeningToken '@{' -ClosingToken '}'
    }

    if ($Value -is [System.Collections.IList]) {
        return Get-PowerShellCollectionBlockDescriptorForCount -Count $Value.Count -EmptyLiteral '@()' -OpeningToken '@(' -ClosingToken ')'
    }

    throw "Unsupported PowerShell data collection type: $($Value.GetType().FullName)"
}

function Get-PowerShellCollectionBlockDescriptorForCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$Count,
        [Parameter(Mandatory)][string]$EmptyLiteral,
        [Parameter(Mandatory)][string]$OpeningToken,
        [Parameter(Mandatory)][string]$ClosingToken
    )

    if ($Count -eq 0) {
        return [pscustomobject]@{
            EmptyLiteral = $EmptyLiteral
            OpeningToken = $null
            ClosingToken = $null
        }
    }

    return [pscustomobject]@{
        EmptyLiteral = $null
        OpeningToken = $OpeningToken
        ClosingToken = $ClosingToken
    }
}

function Get-PowerShellCollectionBlockItemList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Value,
        [int]$IndentLevel = 0
    )

    $childIndent = Get-PowerShellDataIndent -IndentLevel ($IndentLevel + 1)
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in (Get-PowerShellDataDictionaryKeyList -Dictionary $Value)) {
            $keyLiteral = ConvertTo-PowerShellQuotedStringLiteral -Value $key
            "$childIndent$keyLiteral = $( ConvertTo-PowerShellDataLiteral -Value $Value[$key] -IndentLevel ($IndentLevel + 1) )"
        }

        return
    }

    foreach ($item in $Value) {
        "$childIndent$( ConvertTo-PowerShellDataLiteral -Value $item -IndentLevel ($IndentLevel + 1) )"
    }
}

function Get-PowerShellDataDictionaryKeyList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Dictionary
    )

    $keyList = @($Dictionary.Keys | ForEach-Object {[string]$_})
    if ($Dictionary -is [System.Collections.Specialized.OrderedDictionary] -or
        $Dictionary.GetType().FullName -eq 'System.Management.Automation.OrderedHashtable') {
        return $keyList
    }

    return @($keyList | Sort-Object)
}
