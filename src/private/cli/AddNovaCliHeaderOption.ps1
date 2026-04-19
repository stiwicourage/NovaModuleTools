function Add-NovaCliHeaderOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Options,
        [Parameter(Mandatory)][string]$HeaderArgument
    )

    $separatorIndex = $HeaderArgument.IndexOf('=')
    if ($separatorIndex -lt 1) {
        throw "Invalid header argument: $HeaderArgument. Use Name=Value."
    }

    $headerName = $HeaderArgument.Substring(0, $separatorIndex).Trim()
    $headerValue = $HeaderArgument.Substring($separatorIndex + 1)
    if ( [string]::IsNullOrWhiteSpace($headerName)) {
        throw "Invalid header argument: $HeaderArgument. Use Name=Value."
    }

    if (-not $Options.ContainsKey('Headers')) {
        $Options.Headers = @{}
    }

    $Options.Headers[$headerName] = $headerValue
}

