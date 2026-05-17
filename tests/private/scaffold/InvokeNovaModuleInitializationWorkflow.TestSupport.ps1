function Initialize-NovaModuleScaffold {param($Answer, $Paths, [switch]$Example)}
function Write-NovaModuleProjectJson {param($Answer, [string]$ProjectJsonFile, [switch]$Example)}
function Initialize-NovaModuleAgenticCopilotScaffold {param($Answer, [string]$ProjectRoot, [switch]$Example)}
function Write-Message {param([Parameter(ValueFromPipeline = $true)]$InputObject, [string]$color)}
