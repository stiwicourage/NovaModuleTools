function Install-NovaPSModuleUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$UpdatePlan
    )

    $option = Get-NovaPSModuleUpdateInstallOption
    $result = Install-PSModuleUpdate -Update $UpdatePlan -Confirm:$false -WhatIf:$false @option `
        -TrustRepository:([bool]$UpdatePlan.RequiresRepositoryTrust) -AcceptLicense:([bool]$UpdatePlan.RequiresLicenseAcceptance) -ErrorAction Stop
    return ConvertFrom-NovaPSModuleUpdateResult -Result $result
}

function Get-NovaPSModuleUpdateInstallOption {
    [CmdletBinding()]
    param()

    $command = Get-Command -Name Install-PSModuleUpdate -ErrorAction SilentlyContinue
    if ($null -ne $command -and $command.Parameters.ContainsKey('ReplaceUnmanagedInstallation')) {
        return @{ReplaceUnmanagedInstallation = $true}
    }

    return @{}
}
