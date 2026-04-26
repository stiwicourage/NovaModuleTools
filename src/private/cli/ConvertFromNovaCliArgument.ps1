function Set-NovaCliDeliveryOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Options,
        [Parameter(Mandatory)][string[]]$AllowedOptionNameList,
        [Parameter(Mandatory)][pscustomobject]$Option,
        [Parameter(Mandatory)][string]$Token
    )

    if ($Option.Name -notin $AllowedOptionNameList) {
        Stop-NovaOperation -Message "Unknown argument: $Token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
    }

    $Options[$Option.Name] = $Option.Value
}

function ConvertFrom-NovaCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [string[]]$AllowedOptionNameList = @('Local', 'Repository', 'ModuleDirectoryPath', 'ApiKey', 'SkipTests')
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}
    $index = 0

    while ($index -lt $Arguments.Count) {
        $token = $Arguments[$index]

        switch -Regex ($token) {
            '^(--local|-l)$' {
                Set-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'Local'; Value = $true}) -Token $token
            }
            '^(--repository|-r)$' {
                $value = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--repository'
                Set-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'Repository'; Value = $value}) -Token $token
            }
            '^(--path|-p)$' {
                $value = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--path'
                Set-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'ModuleDirectoryPath'; Value = $value}) -Token $token
            }
            '^(--api-key|-k)$' {
                $value = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--api-key'
                Set-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'ApiKey'; Value = $value}) -Token $token
            }
            '^(--skip-tests|-s)$' {
                Set-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'SkipTests'; Value = $true}) -Token $token
            }
            default {
                Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
            }
        }

        $index++
    }

    return $options
}

function ConvertFrom-NovaPackageCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return ConvertFrom-NovaCliArgument -Arguments $Arguments -AllowedOptionNameList @('SkipTests')
}

