function Get-GitCommitMessageForVersionBump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot '.git'))) {
        return @()
    }

    $format = '%s%n%b%n--END-COMMIT--'
    $lastTagResult = Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('describe', '--tags', '--abbrev=0')
    $logResult = Get-NovaVersionBumpCommitLogResult -ProjectRoot $ProjectRoot -Format $format -LastTagResult $lastTagResult
    return @(ConvertFrom-NovaVersionBumpCommitLogResult -Result $logResult)
}

function Get-NovaVersionBumpCommitLogResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$Format,
        [Parameter(Mandatory)][pscustomobject]$LastTagResult
    )

    $lastTag = Get-NovaGitCommandOutputText -Result $LastTagResult
    if ($LastTagResult.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($lastTag)) {
        return Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('log', "$lastTag..HEAD", "--format=$format")
    }

    return Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments @('log', "--format=$format")
}

function ConvertFrom-NovaVersionBumpCommitLogResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result
    )

    if ($Result.ExitCode -ne 0 -or @($Result.Output).Count -eq 0) {
        return @()
    }

    $text = (@($Result.Output) -join [Environment]::NewLine)
    $commits = $text -split '(?m)^--END-COMMIT--\r?$'
    return @($commits | ForEach-Object {$_.Trim()} | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
}
