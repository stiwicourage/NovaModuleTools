function New-NovaModule {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path
    )

    New-MTModule -Path $Path
}
