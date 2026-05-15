[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'Sync-AgenticCopilotScaffold.psd1'),
    [string]$OutputRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function ConvertTo-AgenticNormalizedRelativePath {
    param([Parameter(Mandatory)][string]$Path)

    $normalizedPath = $Path.Replace('\', '/')
    if ( $normalizedPath.StartsWith('./', [System.StringComparison]::Ordinal)) {
        return $normalizedPath.Substring(2)
    }

    return $normalizedPath.TrimStart('/')
}

function Get-AgenticRelativePath {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$Path
    )

    $relativePath = [System.IO.Path]::GetRelativePath(
            [System.IO.Path]::GetFullPath($RootPath),
            [System.IO.Path]::GetFullPath($Path)
    )

    return ConvertTo-AgenticNormalizedRelativePath -Path $relativePath
}

function Resolve-AgenticRepositoryPath {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$RelativePath
    )

    return [System.IO.Path]::GetFullPath((Join-Path $RootPath $RelativePath))
}

function Test-AgenticPathExcluded {
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string[]]$ExcludedPathList
    )

    $normalizedRelativePath = ConvertTo-AgenticNormalizedRelativePath -Path $RelativePath
    foreach ($excludedPath in $ExcludedPathList) {
        $normalizedExcludedPath = ConvertTo-AgenticNormalizedRelativePath -Path $excludedPath
        if ( $normalizedExcludedPath.EndsWith('/', [System.StringComparison]::Ordinal)) {
            if ( $normalizedRelativePath.StartsWith($normalizedExcludedPath, [System.StringComparison]::Ordinal)) {
                return $true
            }
        } elseif ($normalizedRelativePath -eq $normalizedExcludedPath) {
            return $true
        }
    }

    return $false
}

function Get-AgenticSourceFileListForPath {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$SourcePath
    )

    $resolvedSourcePath = Resolve-AgenticRepositoryPath -RootPath $RootPath -RelativePath $SourcePath
    if (-not (Test-Path -LiteralPath $resolvedSourcePath)) {
        throw "Agentic scaffold source path does not exist: $SourcePath"
    }

    if (Test-Path -LiteralPath $resolvedSourcePath -PathType Leaf) {
        return @(Get-Item -LiteralPath $resolvedSourcePath)
    }

    return @(Get-ChildItem -LiteralPath $resolvedSourcePath -File -Recurse -Force)
}

function ConvertTo-AgenticMirrorSourceFile {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][System.IO.FileInfo]$SourceFile,
        [Parameter(Mandatory)][string[]]$ExcludedPathList
    )

    $relativePath = Get-AgenticRelativePath -RootPath $RootPath -Path $SourceFile.FullName
    if (Test-AgenticPathExcluded -RelativePath $relativePath -ExcludedPathList $ExcludedPathList) {
        return $null
    }

    return [pscustomobject]@{
        SourcePath = $SourceFile.FullName
        RelativePath = $relativePath
    }
}

function Get-AgenticMirrorSourceFile {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string[]]$SourcePathList,
        [Parameter(Mandatory)][string[]]$ExcludedPathList
    )

    foreach ($sourcePath in $SourcePathList) {
        $sourceFileList = @(Get-AgenticSourceFileListForPath -RootPath $RootPath -SourcePath $sourcePath)
        foreach ($sourceFile in $sourceFileList) {
            $mirrorSourceFile = ConvertTo-AgenticMirrorSourceFile -RootPath $RootPath -SourceFile $sourceFile -ExcludedPathList $ExcludedPathList
            if ($null -ne $mirrorSourceFile) {
                $mirrorSourceFile
            }
        }
    }
}

function ConvertTo-AgenticScaffoldContent {
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][object[]]$ReplacementList
    )

    $updatedContent = $Content
    foreach ($replacement in $ReplacementList) {
        $updatedContent = $updatedContent.Replace([string]$replacement.Old, [string]$replacement.New)
    }

    while ( $updatedContent.Contains("`n`n`n")) {
        $updatedContent = $updatedContent.Replace("`n`n`n", "`n`n")
    }

    return $updatedContent
}

function Copy-AgenticScaffoldOwnedPath {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string]$RelativePath
    )

    $sourcePath = Resolve-AgenticRepositoryPath -RootPath $SourceRoot -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Agentic scaffold-owned path does not exist: $RelativePath"
    }

    $targetPath = Join-Path $TargetRoot ($RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $targetDirectory = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Recurse -Force
}

function Write-AgenticMirroredFile {
    param(
        [Parameter(Mandatory)][object]$SourceFile,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][object[]]$ReplacementList
    )

    $targetPath = Join-Path $TargetRoot ($SourceFile.RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
    $targetDirectory = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetDirectory)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    $sourceContent = Get-Content -LiteralPath $SourceFile.SourcePath -Raw
    $targetContent = ConvertTo-AgenticScaffoldContent -Content $sourceContent -ReplacementList $ReplacementList
    Set-Content -LiteralPath $targetPath -Value $targetContent -Encoding utf8 -NoNewline
}

function Assert-AgenticOutputRootSafe {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$TargetPath
    )

    $resolvedRootPath = [System.IO.Path]::GetFullPath($RootPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    $resolvedTargetPath = [System.IO.Path]::GetFullPath($TargetPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar)
    if ($resolvedTargetPath -eq $resolvedRootPath) {
        throw 'Agentic scaffold output root cannot be the repository root.'
    }
}

function Invoke-AgenticCopilotScaffoldSync {
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [Parameter(Mandatory)][string]$ConfigPath,
        [Parameter(Mandatory)][string]$TargetRoot
    )

    $manifest = Import-PowerShellDataFile -LiteralPath $ConfigPath
    $sourceRoot = Resolve-AgenticRepositoryPath -RootPath $RootPath -RelativePath $manifest.OutputPath
    $sourceFileList = @(Get-AgenticMirrorSourceFile -RootPath $RootPath -SourcePathList $manifest.SourcePaths -ExcludedPathList $manifest.ExcludedPaths | Sort-Object RelativePath)
    $stagingParent = Join-Path ([System.IO.Path]::GetTempPath()) "NovaAgenticCopilotScaffold-$([guid]::NewGuid() )"
    $stagingRoot = Join-Path $stagingParent 'agentic-copilot'

    try {
        New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
        foreach ($ownedPath in $manifest.ScaffoldOwnedPaths) {
            Copy-AgenticScaffoldOwnedPath -SourceRoot $sourceRoot -TargetRoot $stagingRoot -RelativePath $ownedPath
        }

        foreach ($sourceFile in $sourceFileList) {
            Write-AgenticMirroredFile -SourceFile $sourceFile -TargetRoot $stagingRoot -ReplacementList $manifest.TextReplacements
        }

        if (Test-Path -LiteralPath $TargetRoot) {
            Remove-Item -LiteralPath $TargetRoot -Recurse -Force
        }

        $targetParent = Split-Path -Parent $TargetRoot
        if (-not (Test-Path -LiteralPath $targetParent)) {
            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        }

        Move-Item -LiteralPath $stagingRoot -Destination $TargetRoot

        return [pscustomobject]@{
            OutputRoot = $TargetRoot
            MirroredFileCount = $sourceFileList.Count
            ScaffoldOwnedPathCount = @($manifest.ScaffoldOwnedPaths).Count
        }
    } finally {
        if (Test-Path -LiteralPath $stagingParent) {
            Remove-Item -LiteralPath $stagingParent -Recurse -Force
        }
    }
}

$resolvedRepositoryRoot = [System.IO.Path]::GetFullPath($RepositoryRoot)
$resolvedManifestPath = [System.IO.Path]::GetFullPath($ManifestPath)
$manifestForOutput = Import-PowerShellDataFile -LiteralPath $resolvedManifestPath
if ( [string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Resolve-AgenticRepositoryPath -RootPath $resolvedRepositoryRoot -RelativePath $manifestForOutput.OutputPath
}

$resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
Assert-AgenticOutputRootSafe -RootPath $resolvedRepositoryRoot -TargetPath $resolvedOutputRoot
Invoke-AgenticCopilotScaffoldSync -RootPath $resolvedRepositoryRoot -ConfigPath $resolvedManifestPath -TargetRoot $resolvedOutputRoot
