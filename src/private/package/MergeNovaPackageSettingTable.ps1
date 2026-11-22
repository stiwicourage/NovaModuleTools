function Merge-NovaPackageSettingTable {
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [AllowNull()]$BaseSettings,
        [AllowNull()]$OverrideSettings
    )

    $mergedSettings = [ordered]@{}
    foreach ($settings in @($BaseSettings, $OverrideSettings)) {
        foreach ($entry in @(Get-NovaPackageSettingEntryList -Settings $settings)) {
            $mergedSettings[$entry.Name] = $entry.Value
        }
    }

    return $mergedSettings
}

function Get-NovaPackageSettingEntryList {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [AllowNull()]$Settings
    )

    if ($null -eq $Settings) {
        return @()
    }

    if ($Settings -is [System.Collections.IDictionary]) {
        return @(Get-NovaDictionaryEntryList -Dictionary $Settings)
    }

    return @(
    $Settings.PSObject.Properties | ForEach-Object {
        [pscustomobject]@{
            Name = $_.Name
            Value = $_.Value
        }
    }
    )
}

function Get-NovaDictionaryEntryList {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Dictionary
    )

    return @(
    $Dictionary.Keys | ForEach-Object {
        [pscustomobject]@{
            Name = $_
            Value = $Dictionary[$_]
        }
    }
    )
}
