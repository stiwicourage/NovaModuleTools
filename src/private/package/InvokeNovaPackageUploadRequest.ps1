function Get-NovaPackageUploadRequestParameterMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$UploadArtifact
    )

    $parameters = @{
        Uri = $UploadArtifact.UploadUrl
        Method = 'Put'
        InFile = $UploadArtifact.PackagePath
    }
    if (@($UploadArtifact.Headers.Keys).Count -gt 0) {
        $parameters.Headers = $UploadArtifact.Headers
    }

    return $parameters
}

function Add-NovaLegacyWebRequestOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Parameters
    )

    $webRequestCommand = Get-Command -Name Invoke-WebRequest -CommandType Cmdlet -ErrorAction Stop
    if ( $webRequestCommand.Parameters.ContainsKey('UseBasicParsing')) {
        $Parameters.UseBasicParsing = $true
    }

    return $Parameters
}

function Invoke-NovaPackageUploadRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$UploadArtifact
    )

    $parameters = Get-NovaPackageUploadRequestParameterMap -UploadArtifact $UploadArtifact
    $parameters = Add-NovaLegacyWebRequestOption -Parameters $parameters
    return Invoke-WebRequest @parameters
}
