function Get-VersionLabelFromCommitSet {param($Messages) return 'Major'}
function Invoke-NovaGitCommand {param($ProjectRoot, $Arguments) return [pscustomobject]@{ExitCode=0; Output=@()}}
function Get-NovaGitCommandOutputText {param($Result) return ($Result.Output -join "`n")}
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Set-NovaVersionLabelGitSequenceMock {
    param([string]$CommitCount)

    $script:i = 0
    Mock Invoke-NovaGitCommand {
        $script:i += 1
        switch ($script:i) {
            1 {[pscustomobject]@{ExitCode=0; Output=@('.git')}}
            2 {[pscustomobject]@{ExitCode=0; Output=@('sha')}}
            3 {[pscustomobject]@{ExitCode=0; Output=@('v1.0.0')}}
            default {[pscustomobject]@{ExitCode=0; Output=@($CommitCount)}}
        }
    }
}
