function Get-VersionLabelFromCommitSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Messages
    )

    if ($Messages | Where-Object {Test-NovaBreakingChangeCommitMessage -Message $_}) {
        return 'Major'
    }

    if ($Messages | Where-Object {$_ -match '(?im)^\s*feat(\(.+\))?:'}) {
        return 'Minor'
    }

    if ($Messages | Where-Object {$_ -match '(?im)^\s*fix(\(.+\))?:'}) {
        return 'Patch'
    }

    return 'Patch'
}

function Test-NovaBreakingChangeCommitMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Message
    )

    return ($Message -cmatch '(?m)^BREAKING[ -]CHANGE:') -or ($Message -match '(?im)^\s*[a-z]+(\(.+\))?!:')
}
