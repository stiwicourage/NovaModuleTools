function Initialize-TestGitRepository {
    param([Parameter(Mandatory)][string]$Path)

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    & git -C $Path init --quiet | Out-Null
    & git -C $Path config user.name 'NovaModuleTools Tests' | Out-Null
    & git -C $Path config user.email 'tests@example.invalid' | Out-Null
    & git -C $Path config core.hooksPath /dev/null | Out-Null
    & git -C $Path config commit.gpgsign false | Out-Null
    & git -C $Path config tag.gpgSign false | Out-Null
}

function New-TestGitCommit {
    param(
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$Message,
        [string]$Body,
        [Parameter(Mandatory)][hashtable]$File
    )

    Set-Content -LiteralPath (Join-Path $RepositoryPath $File.Name) -Value $File.Content -Encoding utf8
    & git -C $RepositoryPath add $File.Name | Out-Null

    if ( [string]::IsNullOrWhiteSpace($Body)) {
        & git -C $RepositoryPath -c core.hooksPath=/dev/null -c commit.gpgsign=false -c commit.template= commit --quiet -m $Message | Out-Null
        return
    }

    & git -C $RepositoryPath -c core.hooksPath=/dev/null -c commit.gpgsign=false -c commit.template= commit --quiet -m $Message -m $Body | Out-Null
}

function New-TestGitTag {
    param(
        [Parameter(Mandatory)][string]$RepositoryPath,
        [Parameter(Mandatory)][string]$TagName
    )

    & git -C $RepositoryPath -c core.hooksPath=/dev/null -c tag.gpgSign=false tag $TagName | Out-Null
}
