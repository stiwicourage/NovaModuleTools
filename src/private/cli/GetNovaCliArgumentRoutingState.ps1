function Merge-NovaCliParameterSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BaseParameters,
        [Parameter(Mandatory)][hashtable]$AdditionalParameters
    )

    foreach ($parameterName in $AdditionalParameters.Keys) {
        $BaseParameters[$parameterName] = $AdditionalParameters[$parameterName]
    }

    return $BaseParameters
}

function Get-NovaCliNormalizedRootCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    switch ($Command) {
        '-h' {
            return '--help'
        }
        '-v' {
            return '--version'
        }
        default {
            return $Command
        }
    }
}

function Test-NovaCliMutatingCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    return @('build', 'test', 'package', 'deploy', 'bump', 'update', 'notification', 'publish', 'release') -contains $Command
}

function Test-NovaCliConfirmSupportedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command
    )

    return Test-NovaCliMutatingCommand -Command $Command
}

function Get-NovaCliLegacyOptionReplacement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Option
    )

    $replacementMap = @{
        '-apikey' = "'--api-key' or '-k'"
        '-authenticationscheme' = "'--auth-scheme' or '-a'"
        '-confirm' = "'--confirm' or '-c'"
        '-disable' = "'--disable' or '-d'"
        '-enable' = "'--enable' or '-e'"
        '-example' = "'--example' or '-e'"
        '-header' = "'--header' or '-H'"
        '-installed' = "'--installed' or '-i'"
        '-local' = "'--local' or '-l'"
        '-moduledirectorypath' = "'--path' or '-p'"
        '-packagepath' = "'--path' or '-p'"
        '-packagetype' = "'--type' or '-t'"
        '-path' = "'--path' or '-p'"
        '-preview' = "'--preview' or '-p'"
        '-repository' = "'--repository' or '-r'"
        '-token' = "'--token' or '-k'"
        '-tokenenvironmentvariable' = "'--token-env' or '-e'"
        '-type' = "'--type' or '-t'"
        '-uploadpath' = "'--upload-path' or '-o'"
        '-url' = "'--url' or '-u'"
        '-verbose' = "'--verbose' or '-v'"
        '-whatif' = "'--what-if' or '-w'"
    }

    return $replacementMap[$Option.ToLowerInvariant()]
}

function Test-NovaCliLegacySingleHyphenOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Argument
    )

    return $Argument -match '^-[^-].+$'
}

function Assert-NovaCliArgumentSyntax {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Arguments = @()
    )

    foreach ($argument in $Arguments) {
        if ($argument.ToLowerInvariant() -eq '--whatif') {
            Stop-NovaOperation -Message "Unsupported CLI option syntax: $argument. Use '--what-if' or '-w' instead." -ErrorId 'Nova.Validation.UnsupportedCliOptionSyntax' -Category InvalidArgument -TargetObject $argument
        }

        if (-not (Test-NovaCliLegacySingleHyphenOption -Argument $argument)) {
            continue
        }

        $replacement = Get-NovaCliLegacyOptionReplacement -Option $argument
        $message = if ( [string]::IsNullOrWhiteSpace($replacement)) {
            "Unsupported CLI option syntax: $argument. Use long options with '--' or single-character short options."
        }
        else {
            "Unsupported CLI option syntax: $argument. Use $replacement instead."
        }

        Stop-NovaOperation -Message $message -ErrorId 'Nova.Validation.UnsupportedCliOptionSyntax' -Category InvalidArgument -TargetObject $argument
    }
}


function Add-NovaCliCommonOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Argument,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters
    )

    switch ($Argument) {
        '--confirm' {
            return $true
        }
        '-c' {
            return $true
        }
        '--verbose' {
            $ForwardedParameters.Verbose = $true
            return $true
        }
        '-v' {
            $ForwardedParameters.Verbose = $true
            return $true
        }
        '--what-if' {
            $ForwardedParameters.WhatIf = $true
            return $true
        }
        '-w' {
            $ForwardedParameters.WhatIf = $true
            return $true
        }
        default {
            return $false
        }
    }
}

function Test-NovaCliWhatIfOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Argument
    )

    return $Argument -match '^(--what-if|-w)$'
}

function Test-NovaCliConfirmOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Argument
    )

    return $Argument -match '^(--confirm|-c)$'
}

function Assert-NovaCliConfirmSupportedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [Parameter(Mandatory)][string]$Argument
    )

    if (-not (Test-NovaCliConfirmOption -Argument $Argument)) {
        return
    }

    if (Test-NovaCliConfirmSupportedCommand -Command $Command) {
        return
    }

    Stop-NovaOperation -Message "The 'nova $Command' CLI command does not support '--confirm'/'-c'." -ErrorId 'Nova.Validation.UnsupportedCliConfirm' -Category InvalidOperation -TargetObject 'Confirm'
}

function Get-NovaCliArgumentRoutingState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Command,
        [AllowNull()][string[]]$Arguments
    )

    $normalizedCommand = Get-NovaCliNormalizedRootCommand -Command $Command
    $remainingArguments = [System.Collections.Generic.List[string]]::new()
    $forwardedParameters = @{}
    $whatIfEnabled = $false
    $cliConfirmEnabled = $false

    foreach ($argument in $Arguments) {
        Assert-NovaCliConfirmSupportedCommand -Command $normalizedCommand -Argument $argument

        if ((Test-NovaCliMutatingCommand -Command $normalizedCommand) -and (Add-NovaCliCommonOption -Argument $argument -ForwardedParameters $forwardedParameters)) {
            if (Test-NovaCliWhatIfOption -Argument $argument) {
                $whatIfEnabled = $true
            }

            if (Test-NovaCliConfirmOption -Argument $argument) {
                $cliConfirmEnabled = $true
            }

            continue
        }

        if (($normalizedCommand -eq 'init') -and (Test-NovaCliWhatIfOption -Argument $argument)) {
            $whatIfEnabled = $true
            continue
        }

        $remainingArguments.Add($argument)
    }

    return [pscustomobject]@{
        Command = $normalizedCommand
        Arguments = @($remainingArguments)
        ForwardedParameters = $forwardedParameters
        WhatIfEnabled = $whatIfEnabled
        CliConfirmEnabled = $cliConfirmEnabled
    }
}
