function Get-NovaVersionUpdatePlan {param($ProjectInfo, $Label, [switch]$PreviewRelease, [switch]$StableRelease) return [pscustomobject]@{ProjectFile='/tmp/project.json'; NewVersion=[semver]'1.2.4'}}
function Read-ProjectJsonData {param($ProjectJsonPath) return [pscustomobject]@{Version='1.2.3'}}
function Write-ProjectJsonData {param($ProjectJsonPath, $Data)}
