function Get-ResourceFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FileName
    )

    $candidates = [System.Collections.Generic.List[string]]::new()

    try {
        $projectInfo = Get-NovaProjectInfo -Path (Get-Location).Path
        if (-not [string]::IsNullOrWhiteSpace($projectInfo.ResourcesDir)) {
            $candidates.Add([System.IO.Path]::GetFullPath((Join-Path $projectInfo.ResourcesDir $FileName)))
        }
    }
    catch {
        Write-Verbose "Project resource discovery unavailable, falling back to module-relative resources: $( $_.Exception.Message )"
    }

    foreach ($candidate in @(
        (Join-Path $PSScriptRoot "resources/$FileName"),
        (Join-Path $PSScriptRoot "../resources/$FileName")
    )) {
        $candidates.Add([System.IO.Path]::GetFullPath($candidate))
    }

    $candidates = $candidates | Select-Object -Unique

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    throw "Resource file not found: $FileName. Checked: $( $candidates -join ', ' )"
}
