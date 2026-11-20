function Get-NovaLatestVersionTagResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $arguments = @('describe', '--tags', '--abbrev=0', '--match', 'v[0-9]*.[0-9]*.[0-9]*', '--match', '[0-9]*.[0-9]*.[0-9]*')
    return Invoke-NovaGitCommand -ProjectRoot $ProjectRoot -Arguments $arguments
}
