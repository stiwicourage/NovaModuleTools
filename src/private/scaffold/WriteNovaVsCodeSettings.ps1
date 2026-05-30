function Write-NovaVsCodeSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'VS Code settings is the domain term for the .vscode/settings.json file.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $moduleVersion = $ExecutionContext.SessionState.Module.Version
    if ($null -eq $moduleVersion) { return }

    $schemaUrl = "https://www.novamoduletools.com/schema/v$($moduleVersion.Major)/project.json"
    $vsCodeDir = Join-Path $ProjectRoot '.vscode'
    $settingsFile = Join-Path $vsCodeDir 'settings.json'

    if (Test-Path -LiteralPath $settingsFile) {
        Add-NovaVsCodeJsonSchemaEntry -SettingsFile $settingsFile -SchemaUrl $schemaUrl
    } else {
        New-NovaVsCodeSettingsFile -VsCodeDir $vsCodeDir -SettingsFile $settingsFile -SchemaUrl $schemaUrl
    }
}

function Add-NovaVsCodeJsonSchemaEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SettingsFile,
        [Parameter(Mandatory)][string]$SchemaUrl
    )

    $settings = Get-Content -LiteralPath $SettingsFile -Raw | ConvertFrom-Json -AsHashtable
    if (-not $settings) { $settings = @{} }
    if (-not $settings.ContainsKey('json.schemas')) { $settings['json.schemas'] = @() }

    $schemas = @($settings['json.schemas'])
    $alreadyMapped = $schemas | Where-Object {
        $fm = Resolve-NovaFileMatchArray $_
        ($fm -contains '/project.json') -or ($fm -contains 'project.json')
    }
    if ($alreadyMapped) { return }

    $settings['json.schemas'] = $schemas + @{ fileMatch = @('/project.json'); url = $SchemaUrl }
    $settings | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SettingsFile -Encoding utf8NoBOM
}

function Resolve-NovaFileMatchArray {
    [CmdletBinding()]
    param($Entry)

    $raw = if ($Entry -is [hashtable]) { $Entry['fileMatch'] } else { $Entry.fileMatch }
    return @($raw)
}

function New-NovaVsCodeSettingsFile {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Private file-writing helper. ShouldProcess is managed at the public Initialize-NovaModule command level.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VsCodeDir,
        [Parameter(Mandatory)][string]$SettingsFile,
        [Parameter(Mandatory)][string]$SchemaUrl
    )

    if (-not (Test-Path -LiteralPath $VsCodeDir)) {
        New-Item -ItemType Directory -Path $VsCodeDir | Out-Null
    }
    @{ 'json.schemas' = @(@{ fileMatch = @('/project.json'); url = $SchemaUrl }) } |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $SettingsFile -Encoding utf8NoBOM
}
