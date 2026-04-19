function Get-NovaPackageUploadStatusCode {
    [CmdletBinding()]
    param(
        [AllowNull()]$Response
    )

    if ($null -eq $Response) {
        return $null
    }

    if ($Response.PSObject.Properties.Name -contains 'StatusCode') {
        return [int]$Response.StatusCode
    }

    return $null
}

