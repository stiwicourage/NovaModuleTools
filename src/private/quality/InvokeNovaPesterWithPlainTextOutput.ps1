function Invoke-NovaPesterWithPlainTextOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Configuration
    )

    $originalNoColor = $env:NO_COLOR
    $previousRendering = $null

    if ($null -ne $PSStyle -and $PSStyle.PSObject.Properties.Name -contains 'OutputRendering') {
        $previousRendering = $PSStyle.OutputRendering
        $PSStyle.OutputRendering = 'PlainText'
    }

    $env:NO_COLOR = '1'

    try {
        return Invoke-Pester -Configuration $Configuration
    }
    finally {
        if ($null -ne $previousRendering) {
            $PSStyle.OutputRendering = $previousRendering
        }

        if ($null -eq $originalNoColor) {
            Remove-Item Env:NO_COLOR -ErrorAction SilentlyContinue
        }
        else {
            $env:NO_COLOR = $originalNoColor
        }
    }
}
