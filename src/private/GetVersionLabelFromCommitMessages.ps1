function Get-VersionLabelFromCommitSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Messages
    )

    if ($Messages | Where-Object {$_ -match '(?im)BREAKING CHANGE|^[a-z]+(\(.+\))?!:'}) {
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

