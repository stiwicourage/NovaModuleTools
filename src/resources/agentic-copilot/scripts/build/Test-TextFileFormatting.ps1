[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

function Test-TextFileFormatting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $violationList = @(Get-TextFileFormattingViolationList -ProjectRoot $ProjectRoot)
    return [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        IsValid = $violationList.Count -eq 0
        Violations = $violationList
    }
}

function Get-TextFileFormattingViolationList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    foreach ($file in @(Get-TextFileFormattingTargetFileList -ProjectRoot $ProjectRoot)) {
        if (-not (Test-TextFileFormattingContentHasSingleTrailingNewline -Path $file.FullName)) {
            Get-TextFileFormattingRelativePath -ProjectRoot $ProjectRoot -Path $file.FullName
        }
    }
}

function Get-TextFileFormattingTargetFileList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $rootFileList = @(Get-ChildItem -LiteralPath $ProjectRoot -Force -File | Where-Object {Test-TextFileFormattingCandidate -FileInfo $_})
    $scopedFileList = foreach ($relativePath in @('.github', 'docs', 'scripts', 'src', 'tests')) {
        $directoryPath = Join-Path $ProjectRoot $relativePath
        if (-not (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            continue
        }

        Get-ChildItem -LiteralPath $directoryPath -Recurse -Force -File | Where-Object {Test-TextFileFormattingCandidate -FileInfo $_}
    }

    return @($rootFileList + $scopedFileList | Sort-Object FullName -Unique)
}

function Test-TextFileFormattingCandidate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$FileInfo
    )

    $allowedExtensionList = @(
        '.md',
        '.ps1',
        '.psd1',
        '.psm1',
        '.json',
        '.txt',
        '.yml',
        '.yaml',
        '.html'
    )
    $allowedNameList = @(
        '.gitignore',
        '.gitattributes',
        '.editorconfig'
    )

    return $allowedExtensionList -contains $FileInfo.Extension -or $allowedNameList -contains $FileInfo.Name
}

function Test-TextFileFormattingContentHasSingleTrailingNewline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $content = Get-Content -LiteralPath $Path -Raw
    if ($null -eq $content -or $content.Length -eq 0) {
        return $true
    }

    if ($content -notmatch "(\r\n|\n)$") {
        return $false
    }

    return $content -notmatch "(\r\n|\n){2,}$"
}

function Get-TextFileFormattingRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Path
    )

    $trimCharacterList = [char[]]@(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    $resolvedProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot).TrimEnd($trimCharacterList)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($resolvedProjectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path
    }

    $relativePath = $resolvedPath.Substring($resolvedProjectRoot.Length).TrimStart($trimCharacterList)
    return $relativePath.Replace('\', '/')
}

if ($MyInvocation.InvocationName -ne '.') {
    $result = Test-TextFileFormatting -ProjectRoot $ProjectRoot
    if (-not $result.IsValid) {
        $message = @(
            'Text file ending violations were found. Each tracked text file must end immediately after exactly one newline terminator, with no blank spacer lines at the bottom.'
            @($result.Violations | ForEach-Object {"- $_"})
        ) -join [Environment]::NewLine

        throw $message
    }

    Write-Host 'All tracked text files end immediately after exactly one newline terminator with no extra blank lines at the bottom.'
}
