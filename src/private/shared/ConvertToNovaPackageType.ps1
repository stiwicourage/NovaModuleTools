function ConvertTo-NovaPackageType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Type
    )

    switch ( $Type.Trim().ToLowerInvariant()) {
        'nuget' {
            return 'NuGet'
        }
        '.nupkg' {
            return 'NuGet'
        }
        'zip' {
            return 'Zip'
        }
        '.zip' {
            return 'Zip'
        }
        default {
            Stop-NovaOperation -Message "Unsupported Package.Types value: $Type. Supported values: NuGet, Zip, .nupkg, .zip." -ErrorId 'Nova.Configuration.UnsupportedPackageType' -Category InvalidData -TargetObject $Type
        }
    }
}
