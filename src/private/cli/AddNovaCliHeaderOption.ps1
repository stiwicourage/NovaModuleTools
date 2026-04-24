function Add-NovaCliHeaderOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Options,
        [Parameter(Mandatory)][string]$HeaderArgument
    )

    $separatorIndex = $HeaderArgument.IndexOf('=')
    $headerName = if ($separatorIndex -ge 1) {
        $HeaderArgument.Substring(0, $separatorIndex).Trim()
    }
    else {
        $null
    }
    if ($separatorIndex -lt 1 -or [string]::IsNullOrWhiteSpace($headerName)) {
        Stop-NovaOperation -Message "Invalid header argument: $HeaderArgument. Use Name=Value." -ErrorId 'Nova.Validation.InvalidCliHeaderArgument' -Category InvalidArgument -TargetObject $HeaderArgument
    }

    $headerValue = $HeaderArgument.Substring($separatorIndex + 1)

    if (-not $Options.ContainsKey('Headers')) {
        $Options.Headers = @{}
    }

    $Options.Headers[$headerName] = $headerValue
}

