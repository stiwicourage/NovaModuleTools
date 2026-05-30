function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
    $exception = [System.Exception]::new($Message)
    $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $record
}
function Get-NovaBuildProjectInfo {param($ProjectInfo); return $ProjectInfo}
function Test-ProjectSchema {}
function Export-NovaProjectJsonSchema {}
function Add-ProjectPreambleToModuleBuilder {param($Builder, $ProjectInfo)}
function Get-ProjectScriptFile {param($ProjectInfo); return @()}
function Add-ScriptFileContentToModuleBuilder {param($Builder, $ProjectInfo, $File)}
function Invoke-NovaBuild {} # so (Get-Command Invoke-NovaBuild).Version is resolvable
