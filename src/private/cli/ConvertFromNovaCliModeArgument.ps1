function Get-NovaCliModeArgumentValue {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][pscustomobject]$Definition
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    if ($Arguments.Count -eq 0) {
        return $Definition.EmptyResult
    }

    if ($Arguments.Count -ne 1) {
        Stop-NovaOperation -Message $Definition.Usage.Message -ErrorId $Definition.Usage.ErrorId -Category InvalidArgument -TargetObject $Arguments
    }

    $value = $Definition.TokenMap[$Arguments[0]]
    if ($null -ne $value) {
        return $value
    }

    if ($Definition.UnknownArgumentUsesUsageError) {
        Stop-NovaOperation -Message $Definition.Usage.Message -ErrorId $Definition.Usage.ErrorId -Category InvalidArgument -TargetObject $Arguments
    }

    Stop-NovaOperation -Message "Unknown argument: $( $Arguments[0] )" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $Arguments[0]
}
