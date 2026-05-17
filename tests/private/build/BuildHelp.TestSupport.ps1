function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
    $exception = [System.Exception]::new($Message)
    $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $record
}
function Get-NovaBuildProjectInfo {param($ProjectInfo); return $ProjectInfo}
function Get-NovaHelpLocale {param($HelpMarkdownFiles); return 'en-US'}
function Measure-PlatyPSMarkdown {[CmdletBinding()] param([Parameter(ValueFromPipeline)]$Input) process {}}
function Import-MarkdownCommandHelp {[CmdletBinding()] param([Parameter(ValueFromPipeline)]$Input, $Path) process {}}
function Export-MamlCommandHelp {[CmdletBinding()] param([Parameter(ValueFromPipeline)]$Input, $OutputFolder) process {}}
