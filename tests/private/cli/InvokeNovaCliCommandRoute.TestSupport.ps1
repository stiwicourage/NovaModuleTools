function Stop-NovaOperation {
    param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)

    $exception = [System.Exception]::new($Message)
    $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
    throw $record
}

function Test-NovaCliMutatingCommand {
    param([string]$Command)

    return @('build', 'test', 'package', 'deploy', 'bump', 'update', 'notification', 'publish', 'release') -contains $Command
}

function Confirm-NovaCliCommandAction {
    param([string]$Command)
}

function Get-NovaCliHelp {}

function Get-NovaCliCommandHelp {
    param([string]$Command, [string]$View)
}

function Get-NovaProjectInfo {}

function Invoke-NovaCliVersionCommand {
    param($Arguments, $ForwardedParameters)
}

function Invoke-NovaCliDeployCommand {
    param($Arguments, $ForwardedParameters)
}

function Invoke-NovaCliInitCommand {
    param($Arguments, $ForwardedParameters, [switch]$WhatIfEnabled)
}

function Invoke-NovaCliUpdateCommand {
    param($Arguments, $ForwardedParameters)
}

function Invoke-NovaCliNotificationCommand {
    param($Arguments, $CommonParameters, $MutatingCommonParameters)
}

function Get-NovaCliInstalledVersion {}

function Format-NovaCliVersionString {
    param([string]$Name, $Version)
}

function Format-NovaCliCommandResult {
    param([string]$Command, $Result)

    return $Result
}

function ConvertFrom-NovaBumpCliArgument {
    param($Arguments)
}

function ConvertFrom-NovaBuildCliArgument {
    param($Arguments)
}

function ConvertFrom-NovaTestCliArgument {
    param($Arguments)
}

function ConvertFrom-NovaPackageCliArgument {
    param($Arguments)
}

function ConvertFrom-NovaCliArgument {
    param($Arguments)
}

function Update-NovaModuleVersion {}

function Invoke-NovaBuild {}

function Test-NovaBuild {}

function New-NovaModulePackage {}

function Publish-NovaModule {}

function Invoke-NovaRelease {}

function New-TestContext {
    param(
        [string]$Command = 'info',
        [object[]]$Arguments = @(),
        [hashtable]$CommonParameters = @{},
        [hashtable]$MutatingCommonParameters = @{},
        [bool]$IsHelpRequest = $false,
        [pscustomobject]$HelpRequest = $null,
        [string]$ModuleName = 'NovaModuleTools',
        [bool]$WhatIfEnabled = $false,
        [bool]$CliConfirmEnabled = $false
    )

    return [pscustomobject]@{
        Command = $Command
        Arguments = $Arguments
        CommonParameters = $CommonParameters
        MutatingCommonParameters = $MutatingCommonParameters
        IsHelpRequest = $IsHelpRequest
        HelpRequest = $HelpRequest
        ModuleName = $ModuleName
        WhatIfEnabled = $WhatIfEnabled
        CliConfirmEnabled = $CliConfirmEnabled
    }
}
