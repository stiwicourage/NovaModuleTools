function Assert-TestStructuredCliError {
    [CmdletBinding()]
    param(
        [AllowNull()]$ThrownError,
        [Parameter(Mandatory)][pscustomobject]$ExpectedError
    )

    $ThrownError | Should -Not -BeNullOrEmpty
    $ThrownError.Exception.Message | Should -BeLike $ExpectedError.Message
    $ThrownError.FullyQualifiedErrorId | Should -Be $ExpectedError.ErrorId
    $ThrownError.CategoryInfo.Category | Should -Be $ExpectedError.Category
    if ($ExpectedError.PSObject.Properties.Name -contains 'TargetObject') {
        $ThrownError.TargetObject | Should -Be $ExpectedError.TargetObject
    }
}

