function Test-NovaGitCommandAvailable {return $true}
function Invoke-NovaGitCommand {param($ProjectRoot, $Arguments) return [pscustomobject]@{ExitCode=0; Output=@()}}
function Get-NovaGitCommandOutputText {param($Result) return ($Result.Output -join "`n")}
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
