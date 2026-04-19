function Get-NovaPackageRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string]$Repository
    )

    if ( [string]::IsNullOrWhiteSpace($Repository)) {
        return $null
    }

    $requestedRepository = $Repository.Trim()
    $repositoryList = @(Get-NovaPackageSettingValue -InputObject $ProjectInfo.Package -Name 'Repositories')
    $resolvedRepository = @(
    $repositoryList |
            Where-Object {
                $name = "$( Get-NovaPackageSettingValue -InputObject $_ -Name 'Name' )".Trim()
                $name.Equals($requestedRepository, [System.StringComparison]::OrdinalIgnoreCase)
            } |
            Select-Object -First 1
    )

    if ($resolvedRepository.Count -eq 1) {
        return $resolvedRepository[0]
    }

    throw "Package repository not found: $Repository. Define it under Package.Repositories in project.json or provide -Url."
}

