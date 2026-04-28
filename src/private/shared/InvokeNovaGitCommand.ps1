function Test-NovaGitCommandAvailable {
    [CmdletBinding()]
    param()

    return $null -ne (Get-Command -Name 'git' -ErrorAction SilentlyContinue)
}

function Invoke-NovaGitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $output = & git -C $ProjectRoot @Arguments 2> $null
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = @($output)
    }
}

function Get-NovaGitCommandOutputText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    return (@($Result.Output) -join [Environment]::NewLine).Trim()
}
