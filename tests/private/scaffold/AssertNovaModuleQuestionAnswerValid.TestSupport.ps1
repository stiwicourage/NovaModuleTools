function Get-AwesomePromptValidationFailure {param($Ask, $Value)}
function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
    throw $Message
}
