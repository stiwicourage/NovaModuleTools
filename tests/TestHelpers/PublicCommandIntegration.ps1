function Get-NovaPublicCommandIntegrationProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    return [pscustomobject]@{
        ProjectName = 'NovaModuleTools'
        OutputModuleDir = Join-Path $ProjectRoot 'dist/NovaModuleTools'
    }
}

function Import-NovaPublicCommandIntegrationModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    . (Join-Path $ProjectRoot 'src/private/shared/ImportNovaBuiltModuleForCi.ps1')

    $projectInfo = Get-NovaPublicCommandIntegrationProjectInfo -ProjectRoot $ProjectRoot
    return Import-NovaBuiltModuleForCi -ProjectRoot $ProjectRoot -ProjectInfo $projectInfo
}

function Invoke-NovaPublicCommandIntegrationInLocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    Push-Location -LiteralPath $Path
    try {
        return & $ScriptBlock
    } finally {
        Pop-Location
    }
}

function Invoke-NovaPublicCommandIntegrationInProjectRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    return Invoke-NovaPublicCommandIntegrationInLocation -Path $ProjectRoot -ScriptBlock $ScriptBlock
}

function Get-NovaPublicCommandIntegrationOutputText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Output,
        [switch]$NormalizeWhitespace
    )

    $text = @($Output) -join [Environment]::NewLine
    $text = [regex]::Replace($text, '\x1B\[[0-?]*[ -/]*[@-~]', '')
    if ($NormalizeWhitespace) {
        $text = [regex]::Replace($text, '\s+', ' ')
    }

    return $text.Trim()
}

function Invoke-NovaPublicCommandIntegrationInIsolatedSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [string]$Path = $ProjectRoot,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    $runnerPath = Join-Path $TestDrive 'Run-NovaPublicCommandIntegration.ps1'
    $moduleManifestPath = Join-Path $ProjectRoot 'dist/NovaModuleTools/NovaModuleTools.psd1'
    $escapedManifestPath = $moduleManifestPath.Replace("'", "''")
    $escapedLocationPath = $Path.Replace("'", "''")
    $runnerContent = @"
function New-NovaPublicCommandIntegrationPesterModule {
    param(
        [Parameter(Mandatory)][string]`$BasePath,
        [Parameter(Mandatory)][string]`$Version
    )

    `$moduleRoot = Join-Path `$BasePath "Pester/`$Version"
    `$null = New-Item -ItemType Directory -Path `$moduleRoot -Force
    Set-Content -LiteralPath (Join-Path `$moduleRoot 'Pester.psm1') -Value '' -Encoding utf8
    `$manifestContent = @(
        '@{'
        "    RootModule = 'Pester.psm1'"
    "    ModuleVersion = '`$Version'"
    "    GUID = '`$([guid]::NewGuid().Guid)'"
        '    FunctionsToExport = @()'
        '    CmdletsToExport = @()'
        '    VariablesToExport = @()'
        '    AliasesToExport = @()'
        '}'
    ) -join [Environment]::NewLine
    Set-Content -LiteralPath (Join-Path `$moduleRoot 'Pester.psd1') -Value `$manifestContent -Encoding utf8
}

Import-Module '$escapedManifestPath' -Force -ErrorAction Stop
Set-Location -LiteralPath '$escapedLocationPath'
& {
$($ScriptBlock.ToString() )
}
"@
    Set-Content -LiteralPath $runnerPath -Value $runnerContent -Encoding utf8

    $output = & pwsh -NoLogo -NoProfile -File $runnerPath 2>&1
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output)
    }
}

