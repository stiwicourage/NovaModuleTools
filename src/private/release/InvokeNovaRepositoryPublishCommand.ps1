function Invoke-NovaRepositoryPublishCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$PublishParameters
    )

    Publish-PSResource @PublishParameters
}
