param(
    [string]$ProjectRoot,
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-MirrorStatusProjectRoot {
    param([string]$ProjectRoot)

    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        return (Resolve-Path -LiteralPath $ProjectRoot -ErrorAction Stop).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..')).Path
}

function Get-SourceMirrorEntry {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$SourceRelative
    )

    $sourceFull = Join-Path $ProjectRoot $SourceRelative
    if (-not (Test-Path -LiteralPath $sourceFull -PathType Leaf)) {
        return $null
    }

    $sourceFileName = [System.IO.Path]::GetFileNameWithoutExtension($sourceFull)
    $testRelativeParent = ($SourceRelative -replace '^src/', 'tests/')
    $testRelativeParent = Split-Path -Parent $testRelativeParent
    $testRelative = Join-Path $testRelativeParent ("$sourceFileName.Tests.ps1")
    $testRelative = $testRelative -replace '\\', '/'
    $testFull = Join-Path $ProjectRoot $testRelative

    return [pscustomobject]@{
        SourcePath = $SourceRelative
        TestPath = $testRelative
        Mirrored = Test-Path -LiteralPath $testFull -PathType Leaf
    }
}

function Get-SourceMirrorStatus {
    param([Parameter(Mandatory)][string]$ProjectRoot)

    $sourcePatterns = @(
        'src/public/*.ps1'
        'src/private/*.ps1'
        'src/private/*/*.ps1'
        'src/private/*/*/*.ps1'
        'src/classes/*.ps1'
    )

    $entries = New-Object System.Collections.Generic.List[object]
    foreach ($pattern in $sourcePatterns) {
        $patternPath = Join-Path $ProjectRoot $pattern
        foreach ($file in Get-ChildItem -Path $patternPath -File -ErrorAction SilentlyContinue) {
            $relative = ($file.FullName.Substring($ProjectRoot.Length + 1)) -replace '\\', '/'
            $entry = Get-SourceMirrorEntry -ProjectRoot $ProjectRoot -SourceRelative $relative
            if ($null -ne $entry) {
                $entries.Add($entry)
            }
        }
    }

    return $entries
}

function Write-MirrorStatusReport {
    param(
        [Parameter(Mandatory)][object[]]$Entries,
        [switch]$Quiet
    )

    $missing = @($Entries | Where-Object {-not $_.Mirrored})
    $covered = @($Entries | Where-Object {$_.Mirrored})

    if (-not $Quiet) {
        Write-Host ('Source files scanned : {0}' -f $Entries.Count)
        Write-Host ('Mirrored test files  : {0}' -f $covered.Count)
        Write-Host ('Missing mirrored test: {0}' -f $missing.Count)
        if ($missing.Count -gt 0) {
            Write-Host ''
            Write-Host 'Sources without a mirrored test file:'
            foreach ($entry in $missing | Sort-Object SourcePath) {
                Write-Host ("  {0} -> {1}" -f $entry.SourcePath, $entry.TestPath)
            }
        }
    }
}

$resolvedRoot = Resolve-MirrorStatusProjectRoot -ProjectRoot $ProjectRoot
$entries = Get-SourceMirrorStatus -ProjectRoot $resolvedRoot
Write-MirrorStatusReport -Entries $entries -Quiet:$Quiet
return $entries
