function Get-NovaPackageAuthorList {
    [CmdletBinding()]
    param(
        [AllowNull()]$AuthorValue
    )

    if ($null -eq $AuthorValue) {
        return @()
    }

    if ($AuthorValue -is [string]) {
        if ( [string]::IsNullOrWhiteSpace($AuthorValue)) {
            return @()
        }

        return @($AuthorValue.Trim())
    }

    if ($AuthorValue -isnot [System.Collections.IEnumerable]) {
        Stop-NovaOperation -Message 'Package.Authors must be a string or an array of strings.' -ErrorId 'Nova.Configuration.PackageAuthorsInvalidType' -Category InvalidData -TargetObject $AuthorValue
    }

    return @(
    $AuthorValue |
            ForEach-Object {"$( $_ )".Trim()} |
            Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |
            Select-Object -Unique
    )
}
