function Get-AwesomePromptFieldDescription {param($Ask) return [pscustomobject]@{Name = 'field'}}
function Get-AwesomePromptValue {param($Ask, [string]$Name) return $Name}
function Test-AwesomePromptRequiresRetry {param($Ask, $Response) return $false}
function Write-AwesomePromptRetryMessage {param($Ask, $Response)}
function Get-AwesomePromptResult {param($Ask, $Response) return 'final'}
