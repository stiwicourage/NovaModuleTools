function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)

    $exception = [System.Exception]::new($Message)
    $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $record
}

function New-DuplicateValidationProjectInfo {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ModuleContent,
        [Parameter(Mandatory)][hashtable]$SourceFileMap
    )

    $classesDir = Join-Path $ProjectRoot 'src/classes'
    $publicDir = Join-Path $ProjectRoot 'src/public'
    $privateDir = Join-Path $ProjectRoot 'src/private'
    $outputDir = Join-Path $ProjectRoot 'dist/NovaModuleTools'

    New-Item -ItemType Directory -Path $classesDir, $publicDir, $privateDir, $outputDir -Force | Out-Null

    foreach ($relativePath in $SourceFileMap.Keys) {
        $filePath = Join-Path $ProjectRoot $relativePath
        $directory = Split-Path -Parent $filePath
        if (-not [string]::IsNullOrWhiteSpace($directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        Set-Content -LiteralPath $filePath -Value $SourceFileMap[$relativePath]
    }

    $modulePath = Join-Path $outputDir 'NovaModuleTools.psm1'
    Set-Content -LiteralPath $modulePath -Value $ModuleContent

    return [pscustomobject]@{
        BuildRecursiveFolders = $true
        ProjectRoot = $ProjectRoot
        ClassesDir = $classesDir
        PublicDir = $publicDir
        PrivateDir = $privateDir
        ModuleFilePSM1 = $modulePath
    }
}
