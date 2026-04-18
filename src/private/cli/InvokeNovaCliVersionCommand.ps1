function Invoke-NovaCliVersionCommand {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters
    )

    $options = ConvertFrom-NovaVersionCliArgument -Arguments $Arguments
    if ($options.Installed) {
        return Get-NovaInstalledProjectVersion @ForwardedParameters
    }

    $projectInfo = Get-NovaProjectInfo @ForwardedParameters
    return Format-NovaCliVersionString -Name $projectInfo.ProjectName -Version $projectInfo.Version
}
