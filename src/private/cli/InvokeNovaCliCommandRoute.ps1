function Confirm-NovaCliRoutedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext,
        [Parameter(Mandatory)][string]$Command
    )

    if (-not $InvocationContext.CliConfirmEnabled) {
        return
    }

    if ($InvocationContext.WhatIfEnabled) {
        return
    }

    if (-not (Test-NovaCliMutatingCommand -Command $Command)) {
        return
    }

    Confirm-NovaCliCommandAction -Command $Command
}

function Invoke-NovaCliParsedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext,
        [Parameter(Mandatory)][string]$ParserCommand,
        [Parameter(Mandatory)][string]$ActionCommand,
        [switch]$UsePublishOption
    )

    $arguments = $InvocationContext.Arguments
    $mutatingCommonParameters = $InvocationContext.MutatingCommonParameters
    $options = & $ParserCommand -Arguments $arguments
    if ($UsePublishOption) {
        return & $ActionCommand -PublishOption $options @mutatingCommonParameters
    }

    return & $ActionCommand @options @mutatingCommonParameters
}

function Invoke-NovaCliBumpCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    $commandOutput = @(Invoke-NovaCliParsedCommand -InvocationContext $InvocationContext -ParserCommand 'ConvertFrom-NovaBumpCliArgument' -ActionCommand 'Update-NovaModuleVersion' 3>&1)
    $capturedOutput = Read-NovaCliCapturedOutput -OutputRecords $commandOutput
    Write-NovaCliCapturedWarning -WarningMessages $capturedOutput.WarningMessages
    return $capturedOutput.Result
}

function Read-NovaCliCapturedOutput {
    [CmdletBinding()]
    param(
        [object[]]$OutputRecords = @()
    )

    $warningMessages = @()
    $result = $null
    foreach ($outputRecord in @($OutputRecords)) {
        if ($outputRecord -is [System.Management.Automation.WarningRecord]) {
            $warningMessages += $outputRecord
            continue
        }

        $result = $outputRecord
    }

    return [pscustomobject]@{
        Result = $result
        WarningMessages = @($warningMessages)
    }
}

function Write-NovaCliCapturedWarning {
    [CmdletBinding()]
    param(
        [object[]]$WarningMessages = @()
    )

    foreach ($message in (Get-NovaCliReplayWarningMessage -WarningMessages $WarningMessages)) {
        Write-Warning $message
    }
}

function Get-NovaCliReplayWarningMessage {
    [CmdletBinding()]
    param(
        [object[]]$WarningMessages = @()
    )

    $messages = foreach ($warningMessage in @($WarningMessages)) {
        $text = ConvertTo-NovaCliWarningMessageText -WarningMessage $warningMessage
        if ( [string]::IsNullOrWhiteSpace($text)) {
            continue
        }

        $text
    }

    return @($messages)
}

function ConvertTo-NovaCliWarningMessageText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$WarningMessage
    )

    if ($WarningMessage -is [System.Management.Automation.WarningRecord]) {
        return $WarningMessage.Message
    }

    return [string]$WarningMessage
}

function Invoke-NovaCliUpdateRouteCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    $result = Invoke-NovaCliUpdateCommand -Arguments $InvocationContext.Arguments -ForwardedParameters $InvocationContext.MutatingCommonParameters
    Format-NovaCliCommandResult -Command $InvocationContext.Command -Result $result
}

function Invoke-NovaCliBumpRouteCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    $result = Invoke-NovaCliBumpCommand -InvocationContext $InvocationContext
    return Format-NovaCliCommandResult -Command $InvocationContext.Command -Result $result
}

function Invoke-NovaCliNotificationRouteCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    Invoke-NovaCliNotificationCommand -Arguments $InvocationContext.Arguments -CommonParameters $InvocationContext.CommonParameters -MutatingCommonParameters $InvocationContext.MutatingCommonParameters
}

function Invoke-NovaCliInstalledVersionCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    $moduleVersion = Get-NovaCliInstalledVersion
    Format-NovaCliVersionString -Name $InvocationContext.ModuleName -Version $moduleVersion
}

function Invoke-NovaCliCommandRoute {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InvocationContext
    )

    if ($InvocationContext.IsHelpRequest) {
        if ($InvocationContext.HelpRequest.TargetType -eq 'Root') {
            return Get-NovaCliHelp
        }

        return Get-NovaCliCommandHelp -Command $InvocationContext.HelpRequest.Command -View $InvocationContext.HelpRequest.View
    }

    $command = $InvocationContext.Command
    $commonParameters = $InvocationContext.CommonParameters
    $mutatingCommonParameters = $InvocationContext.MutatingCommonParameters
    Confirm-NovaCliRoutedCommand -InvocationContext $InvocationContext -Command $command

    switch ($command) {
        'info' {
            return Get-NovaProjectInfo @commonParameters
        }
        'version' {
            return Invoke-NovaCliVersionCommand -Arguments $InvocationContext.Arguments -ForwardedParameters $commonParameters
        }
        'build' {
            return Invoke-NovaCliParsedCommand -InvocationContext $InvocationContext -ParserCommand 'ConvertFrom-NovaBuildCliArgument' -ActionCommand 'Invoke-NovaBuild'
        }
        'test' {
            return Invoke-NovaCliParsedCommand -InvocationContext $InvocationContext -ParserCommand 'ConvertFrom-NovaTestCliArgument' -ActionCommand 'Test-NovaBuild'
        }
        'package' {
            return Invoke-NovaCliParsedCommand -InvocationContext $InvocationContext -ParserCommand 'ConvertFrom-NovaPackageCliArgument' -ActionCommand 'New-NovaModulePackage'
        }
        'deploy' {
            return Invoke-NovaCliDeployCommand -Arguments $InvocationContext.Arguments -ForwardedParameters $mutatingCommonParameters
        }
        'init' {
            return Invoke-NovaCliInitCommand -Arguments $InvocationContext.Arguments -ForwardedParameters $mutatingCommonParameters -WhatIfEnabled:$InvocationContext.WhatIfEnabled
        }
        'bump' {
            return Invoke-NovaCliBumpRouteCommand -InvocationContext $InvocationContext
        }
        'update' {
            return Invoke-NovaCliUpdateRouteCommand -InvocationContext $InvocationContext
        }
        'publish' {
            return Invoke-NovaCliParsedCommand -InvocationContext $InvocationContext -ParserCommand 'ConvertFrom-NovaCliArgument' -ActionCommand 'Publish-NovaModule'
        }
        'release' {
            return Invoke-NovaCliParsedCommand -InvocationContext $InvocationContext -ParserCommand 'ConvertFrom-NovaCliArgument' -ActionCommand 'Invoke-NovaRelease' -UsePublishOption
        }
        'notification' {
            return Invoke-NovaCliNotificationRouteCommand -InvocationContext $InvocationContext
        }
        '--version' {
            return Invoke-NovaCliInstalledVersionCommand -InvocationContext $InvocationContext
        }
        '--help' {
            return Get-NovaCliHelp
        }
        default {
            Stop-NovaOperation -Message "Unknown command: <$command> | Use 'nova --help' to see available commands." -ErrorId 'Nova.Validation.UnknownCliCommand' -Category InvalidArgument -TargetObject $command
        }
    }
}
