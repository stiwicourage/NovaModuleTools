function Get-NovaFirstConfiguredValue {
    [CmdletBinding()]
    param(
        [AllowNull()][AllowEmptyCollection()][object[]]$CandidateList = @()
    )

    foreach ($candidate in $CandidateList) {
        if (Test-NovaConfiguredValue -Value $candidate) {
            return $candidate
        }
    }

    return $null
}

function Test-NovaConfiguredValue {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [string]) {
        return -not [string]::IsNullOrWhiteSpace($Value)
    }

    return $true
}
