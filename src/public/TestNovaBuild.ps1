function Test-NovaBuild {
    [CmdletBinding()]
    param(
        [string[]]$TagFilter,
        [string[]]$ExcludeTagFilter
    )

    Invoke-MTTest -TagFilter $TagFilter -ExcludeTagFilter $ExcludeTagFilter
}
