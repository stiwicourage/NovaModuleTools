function ConvertTo-CoverageLineRate {
    param([Parameter(Mandatory)][string]$Value)

    return [double]::Parse($Value, [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-CoverageLowReportEntryList {
    param(
        [Parameter(Mandatory)][string]$CoveragePath,
        [double]$Threshold = 0.9
    )

    [xml]$coverageXml = Get-Content -LiteralPath $CoveragePath -Raw
    $classNodes = @($coverageXml.SelectNodes('/coverage/packages/package/classes/class'))

    return @(
    foreach ($classNode in $classNodes) {
        $lineRate = ConvertTo-CoverageLineRate -Value ([string]$classNode.'line-rate')
        if ($lineRate -ge $Threshold) {
            continue
        }

        [pscustomobject]@{
            Path = [string]$classNode.filename
            LineRate = $lineRate
        }
    }
    )
}

function Format-CoverageLowReportLine {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][double]$LineRate
    )

    return [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '{0:F6} {1}', $LineRate, $Path)
}

function Write-CoverageLowReport {
    param(
        [Parameter(Mandatory)][string]$CoveragePath,
        [Parameter(Mandatory)][string]$OutputPath,
        [double]$Threshold = 0.9
    )

    $reportLines = Get-CoverageLowReportEntryList -CoveragePath $CoveragePath -Threshold $Threshold |
            Sort-Object LineRate, Path |
            ForEach-Object {Format-CoverageLowReportLine -Path $_.Path -LineRate $_.LineRate}

    Set-Content -LiteralPath $OutputPath -Value $reportLines -Encoding utf8
}
