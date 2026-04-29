function Get-AvailableReleaseVersionList {
    param(
        [string]$RepositoryRoot = (Get-Location).Path
    )

    if (-not (Test-Path -LiteralPath (Join-Path $RepositoryRoot '.git'))) {
        return @()
    }

    return @(
    git -C $RepositoryRoot tag --list 'Version_*' |
            ForEach-Object {$_ -replace '^Version_', ''} |
            Where-Object {-not [string]::IsNullOrWhiteSpace($_)}
    )
}
