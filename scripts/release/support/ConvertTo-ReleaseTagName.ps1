function ConvertTo-ReleaseTagName {
    param(
        [Parameter(Mandatory)][string]$Version
    )

    return "Version_$Version"
}

