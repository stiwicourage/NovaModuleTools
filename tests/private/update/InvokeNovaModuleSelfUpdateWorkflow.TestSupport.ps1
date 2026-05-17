function Invoke-NovaModuleSelfUpdate {param([string]$ModuleName,[switch]$AllowPrerelease)}
function Get-NovaModuleReleaseNotesUri {'https://example.com/notes'}
function Stop-NovaOperation {param([string]$Message,[string]$ErrorId,$Category,$TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message),$ErrorId,$Category,$TargetObject)}
