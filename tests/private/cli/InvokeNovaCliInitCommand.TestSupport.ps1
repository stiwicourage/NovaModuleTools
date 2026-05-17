function ConvertFrom-NovaInitCliArgument {param([string[]]$Arguments) return @{Path = '/tmp/proj'}}
function Initialize-NovaModule {param($Path, $Verbose) return [pscustomobject]@{Path = $Path; Verbose = $Verbose}}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
