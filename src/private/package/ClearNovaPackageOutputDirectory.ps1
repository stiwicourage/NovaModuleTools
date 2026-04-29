function Clear-NovaPackageOutputDirectory {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'New-NovaModulePackage performs the user-facing ShouldProcess confirmation before calling this internal cleanup helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$OutputDirectory
    )

    Assert-NovaPackageOutputDirectoryCanBeCleared -ProjectInfo $ProjectInfo -OutputDirectory $OutputDirectory
    if (Test-Path -LiteralPath $OutputDirectory) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }
}
