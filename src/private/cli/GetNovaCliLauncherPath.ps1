function Get-NovaCliLauncherPath {
    [CmdletBinding()]
    param()

    $command = Get-Command -Name 'Install-NovaCli' -CommandType Function -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        Stop-NovaOperation -Message 'Install-NovaCli command not found.' -ErrorId 'Nova.Environment.CliInstallCommandNotFound' -Category ObjectNotFound -TargetObject 'Install-NovaCli'
    }

    $commandFile = $command.ScriptBlock.File
    if ( [string]::IsNullOrWhiteSpace($commandFile)) {
        Stop-NovaOperation -Message 'Install-NovaCli must be loaded from a file-backed module.' -ErrorId 'Nova.Environment.CliInstallCommandNotFileBacked' -Category ResourceUnavailable -TargetObject 'Install-NovaCli'
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

    Stop-NovaOperation -Message "Nova CLI launcher not found. Checked: $( ($candidateList | ForEach-Object {[System.IO.Path]::GetFullPath($_)}) -join ', ' )" -ErrorId 'Nova.Environment.CliLauncherNotFound' -Category ObjectNotFound -TargetObject 'nova'
}
