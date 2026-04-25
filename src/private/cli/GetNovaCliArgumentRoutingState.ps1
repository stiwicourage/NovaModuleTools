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
        '-whatif' = "'--whatif' or '-w'"
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

function Get-NovaCliAliasInvocationStatement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Invocation
    )

    if (-not [string]::IsNullOrWhiteSpace($Invocation.InvocationStatement)) {
        return $Invocation.InvocationStatement
    }

    if ($Invocation.InvocationName -ne 'nova') {
        return $null
    }

    return (@($Invocation.InvocationName, $Invocation.Command) + @($Invocation.Arguments)) -join ' '
}

function Get-NovaCliInvocationParameterTokenSet {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$InvocationStatement
    )

    if ( [string]::IsNullOrWhiteSpace($InvocationStatement)) {
        return @()
    }

    $errors = $null
    $tokens = [System.Management.Automation.PSParser]::Tokenize($InvocationStatement, [ref]$errors)
    return @($tokens | Where-Object Type -eq 'CommandParameter' | Select-Object -ExpandProperty Content)
}

function Get-NovaCliBoundCommonParameterToken {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ParameterName,
        [AllowEmptyCollection()][string[]]$ParameterTokens = @()
    )

    foreach ($token in $ParameterTokens) {
        if ($token -ieq '-v') {
            return $token
        }

        $normalizedToken = $token.TrimStart('-')
        if ( $ParameterName.StartsWith($normalizedToken, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $token
        }
    }

    return $null
}

function Get-NovaCliAliasParameterTokenSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Invocation
    )

    $statement = Get-NovaCliAliasInvocationStatement -Invocation $Invocation
    return Get-NovaCliInvocationParameterTokenSet -InvocationStatement $statement
}

function Test-NovaCliAliasRootVersionShortcut {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Invocation
    )

    return $Invocation.InvocationName -eq 'nova' -and
            $Invocation.Command -eq '--help' -and
            -not $Invocation.BoundParameters.ContainsKey('Command') -and
            $Invocation.BoundParameters.ContainsKey('Verbose')
}

function Assert-NovaCliArgumentSyntax {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Arguments = @()
    )

    foreach ($argument in $Arguments) {
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

function Assert-NovaCliAliasCommonParameterSyntax {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Invocation
    )

    if ($Invocation.InvocationName -ne 'nova') {
        return
    }

    $parameterTokens = Get-NovaCliAliasParameterTokenSet -Invocation $Invocation

    foreach ($parameterName in @('Verbose', 'WhatIf', 'Confirm')) {
        if (-not $Invocation.BoundParameters.ContainsKey($parameterName)) {
            continue
        }

        $parameterToken = Get-NovaCliBoundCommonParameterToken -ParameterName $parameterName -ParameterTokens $parameterTokens
        if ($parameterToken -ieq '-v') {
            continue
        }

        Assert-NovaCliArgumentSyntax -Arguments @($( if ($null -ne $parameterToken) {
            $parameterToken
        } else {
            "-$parameterName"
        } ))
    }
}

function Get-NovaCliAliasRootCommandOverride {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Invocation
    )

    if (-not (Test-NovaCliAliasRootVersionShortcut -Invocation $Invocation)) {
        return $null
    }

    $parameterTokens = Get-NovaCliAliasParameterTokenSet -Invocation $Invocation
    if ($parameterTokens -icontains '-v') {
        return '-v'
    }

    return $null
}

function Add-NovaCliCommonOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Argument,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters
    )

    switch ($Argument) {
        '--confirm' {
            $ForwardedParameters.Confirm = $true
            return $true
        }
        '-c' {
            $ForwardedParameters.Confirm = $true
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
        '--whatif' {
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

    return $Argument -match '^(--whatif|-w)$'
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

    foreach ($argument in $Arguments) {
        if ((Test-NovaCliMutatingCommand -Command $normalizedCommand) -and (Add-NovaCliCommonOption -Argument $argument -ForwardedParameters $forwardedParameters)) {
            if (Test-NovaCliWhatIfOption -Argument $argument) {
                $whatIfEnabled = $true
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
    }
}
