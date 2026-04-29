function Get-NovaCliHelpText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string[]]$Lines
    )

    return ($Lines -join [Environment]::NewLine).TrimEnd()
}

function Get-NovaCliHelpOptionLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Option
    )

    $label = "$( $Option.Short ), $( $Option.Long )"
    if (-not [string]::IsNullOrWhiteSpace($Option.Placeholder)) {
        return "$label $( $Option.Placeholder )"
    }

    return $label
}

function Get-NovaCliHelpOptionLabelWidth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Options
    )

    $width = 0
    foreach ($option in $Options) {
        $width = [Math]::Max($width, (Get-NovaCliHelpOptionLabel -Option $option).Length)
    }

    return $width
}

function Format-NovaCliShortOptionLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Option,
        [Parameter(Mandatory)][int]$LabelWidth
    )

    $label = Get-NovaCliHelpOptionLabel -Option $Option
    return ('  {0}  {1}' -f $label.PadRight($LabelWidth), $Option.Description).TrimEnd()
}

function Format-NovaCliLongOptionBlock {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Option
    )

    return @(
        "  $( Get-NovaCliHelpOptionLabel -Option $Option )"
        "      $( $Option.Description )"
    )
}

function Get-NovaCliShortOptionText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Options
    )

    if ($Options.Count -eq 0) {
        return '  (none)'
    }

    $labelWidth = Get-NovaCliHelpOptionLabelWidth -Options $Options
    return @($Options | ForEach-Object {Format-NovaCliShortOptionLine -Option $_ -LabelWidth $labelWidth})
}

function Get-NovaCliLongOptionText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Options
    )

    if ($Options.Count -eq 0) {
        return '  (none)'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($option in $Options) {
        foreach ($line in (Format-NovaCliLongOptionBlock -Option $option)) {
            $lines.Add($line)
        }

        $lines.Add('')
    }

    if ($lines.Count -gt 0) {
        $lines.RemoveAt($lines.Count - 1)
    }

    return $lines.ToArray()
}

function Get-NovaCliExampleText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Examples
    )

    if ($Examples.Count -eq 0) {
        return '  (none)'
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($example in $Examples) {
        $lines.Add("  $( $example.Command )")
        $lines.Add("      $( $example.Description )")
        $lines.Add('')
    }

    $lines.RemoveAt($lines.Count - 1)
    return $lines.ToArray()
}

function Format-NovaCliShortCommandHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Definition
    )

    $lines = @(
        "usage: $( $Definition.Usage )"
        ''
        $Definition.Summary
        ''
        'Options:'
    ) + (Get-NovaCliShortOptionText -Options $Definition.Options)

    return Get-NovaCliHelpText -Lines $lines
}

function Format-NovaCliLongCommandHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Definition
    )

    $lines = @(
        'NAME'
        "  nova $( $Definition.Command ) - $( $Definition.Summary )"
        ''
        'SYNOPSIS'
        "  $( $Definition.Usage )"
        ''
        'DESCRIPTION'
    ) + @($Definition.Description | ForEach-Object {"  $_"}) + @(
        ''
        'OPTIONS'
    ) + (Get-NovaCliLongOptionText -Options $Definition.Options) + @(
        ''
        'EXAMPLES'
    ) + (Get-NovaCliExampleText -Examples $Definition.Examples)

    return Get-NovaCliHelpText -Lines $lines
}

function Format-NovaCliCommandHelp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Definition,
        [ValidateSet('Short', 'Long')][string]$View = 'Short'
    )

    if ($View -eq 'Long') {
        return Format-NovaCliLongCommandHelp -Definition $Definition
    }

    return Format-NovaCliShortCommandHelp -Definition $Definition
}
