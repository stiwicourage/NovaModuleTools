function Get-NovaCliLauncherPath {
    [CmdletBinding()]
    param()

    $command = Get-Command -Name 'Install-NovaCli' -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw 'Install-NovaCli command not found.'
    }

    $commandFile = $command.ScriptBlock.File
    if ( [string]::IsNullOrWhiteSpace($commandFile)) {
        throw 'Install-NovaCli must be loaded from a file-backed module.'
    }

    $commandRoot = Split-Path -Parent $commandFile
    $candidateList = @(
        (Join-Path $commandRoot 'resources/nova'),
        (Join-Path $commandRoot '../resources/nova')
    )

    foreach ($candidate in $candidateList) {
        $resolvedCandidate = [System.IO.Path]::GetFullPath($candidate)
        if (Test-Path -LiteralPath $resolvedCandidate) {
            return $resolvedCandidate
        }
    }

    throw "Nova CLI launcher not found. Checked: $( ($candidateList | ForEach-Object {[System.IO.Path]::GetFullPath($_)}) -join ', ' )"
}
