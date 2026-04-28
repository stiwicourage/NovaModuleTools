function Get-NovaResolvedProjectPackageTypeList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package type list is the domain term represented by this resolver.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$PackageSettings
    )

    $typeValues = if ($PackageSettings.Contains('Types') -and $null -ne $PackageSettings['Types']) {
        @($PackageSettings['Types'])
    }
    else {
        @()
    }

    $resolvedTypeList = @()
    foreach ($typeValue in $typeValues) {
        if ( [string]::IsNullOrWhiteSpace("$( $typeValue )")) {
            continue
        }

        $resolvedType = ConvertTo-NovaPackageType -Type "$( $typeValue )"
        if ($resolvedType -notin $resolvedTypeList) {
            $resolvedTypeList += $resolvedType
        }
    }

    if ($resolvedTypeList.Count -eq 0) {
        return @('NuGet')
    }

    return $resolvedTypeList
}
