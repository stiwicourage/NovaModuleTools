function Read-NovaJsonFileData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiteralPath
    )

    if (-not (Test-Path -LiteralPath $LiteralPath -PathType Leaf)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $LiteralPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Initialize-NovaDirectoryPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $Path -Force
    }
}

function Write-NovaJsonFileData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)]$Value
    )

    Initialize-NovaDirectoryPath -Path (Split-Path -Parent $LiteralPath)
    $Value | ConvertTo-Json | Set-Content -LiteralPath $LiteralPath -Encoding utf8
}
