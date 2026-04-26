function Add-NovaCliDeliveryOption {
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
        [string[]]$AllowedOptionNameList
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    if ($null -eq $AllowedOptionNameList) {
        $AllowedOptionNameList = @('Local', 'Repository', 'ModuleDirectoryPath', 'ApiKey', 'SkipTests', 'ContinuousIntegration')
    }

    $options = @{}
    $index = 0

    while ($index -lt $Arguments.Count) {
        $token = $Arguments[$index]

        switch -Regex ($token) {
            '^(--local|-l)$' {
                Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'Local'; Value = $true}) -Token $token
            }
            '^(--repository|-r)$' {
                $value = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--repository'
                Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'Repository'; Value = $value}) -Token $token
            }
            '^(--path|-p)$' {
                $value = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--path'
                Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'ModuleDirectoryPath'; Value = $value}) -Token $token
            }
            '^(--api-key|-k)$' {
                $value = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--api-key'
                Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'ApiKey'; Value = $value}) -Token $token
            }
            '^(--skip-tests|-s)$' {
                Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'SkipTests'; Value = $true}) -Token $token
            }
            '^(--continuous-integration|-i)$' {
                Add-NovaCliDeliveryOption -Options $options -AllowedOptionNameList $AllowedOptionNameList -Option ([pscustomobject]@{Name = 'ContinuousIntegration'; Value = $true}) -Token $token
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

