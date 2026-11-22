function Import-NovaPSModuleUpdateDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Cmdlet
    )

    $minimumVersion = [version]'0.3.0'
    if (-not (Test-NovaPSModuleUpdateInstalled -MinimumVersion $minimumVersion)) {
        Install-NovaPSModuleUpdateDependency -Cmdlet $Cmdlet -MinimumVersion $minimumVersion
    }

    Import-Module -Name PSModuleUpdate -MinimumVersion $minimumVersion -ErrorAction Stop
}

function Test-NovaPSModuleUpdateInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][version]$MinimumVersion
    )

    $installed = @(Get-Module -ListAvailable -Name PSModuleUpdate | Where-Object {$_.Version -ge $MinimumVersion})
    return $installed.Count -gt 0
}

function Install-NovaPSModuleUpdateDependency {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is delegated to the calling public cmdlet so -WhatIf and -Confirm apply to the whole self-update.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Cmdlet,
        [Parameter(Mandatory)][version]$MinimumVersion
    )

    $errorId = 'Nova.Dependency.PSModuleUpdateUnavailable'
    if (-not $Cmdlet.ShouldProcess('PSModuleUpdate', "Install PSModuleUpdate $MinimumVersion or later from PSGallery for the current user")) {
        Stop-NovaOperation -Message (Get-NovaPSModuleUpdateUnavailableMessage -MinimumVersion $MinimumVersion) -ErrorId $errorId -Category NotInstalled -TargetObject 'PSModuleUpdate'
    }

    Write-Message "Installing PSModuleUpdate $MinimumVersion or later, which NovaModuleTools uses to update itself."
    try {
        Install-PSResource -Name PSModuleUpdate -Version "[$MinimumVersion,)" -Repository PSGallery -Scope CurrentUser -TrustRepository -Quiet -ErrorAction Stop
    } catch {
        $message = Get-NovaPSModuleUpdateUnavailableMessage -MinimumVersion $MinimumVersion -FailureDetail $_.Exception.Message
        Stop-NovaOperation -Message $message -ErrorId $errorId -Category NotInstalled -TargetObject 'PSModuleUpdate'
    }
}

function Get-NovaPSModuleUpdateUnavailableMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][version]$MinimumVersion,
        [string]$FailureDetail
    )

    return @(
        "NovaModuleTools needs PSModuleUpdate $MinimumVersion or later to update itself."
        if (-not [string]::IsNullOrWhiteSpace($FailureDetail)) {
            "Installing PSModuleUpdate failed: $FailureDetail"
        }
        'Install it with: Install-PSResource -Name PSModuleUpdate -Scope CurrentUser -Repository PSGallery'
        'Then rerun Update-NovaModuleTool.'
    ) -join [Environment]::NewLine
}
