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

function Resolve-TestPublicDocsUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$DocsRoot
    )

    $publicDocsBaseUrl = 'https://www.novamoduletools.com/'
    if (-not $Url.StartsWith($publicDocsBaseUrl, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Unsupported docs URL: $Url"
    }

    $relativeUrl = $Url.Substring($publicDocsBaseUrl.Length)
    $segments = $relativeUrl -split '#', 2
    $pageName = $segments[0]
    if ( [string]::IsNullOrWhiteSpace($pageName)) {
        $pageName = 'index.html'
    }

    return [pscustomobject]@{
        Url = $Url
        FilePath = Join-Path $DocsRoot $pageName
        Anchor = if ($segments.Count -gt 1) {
            $segments[1]
        } else {
            $null
        }
    }
}

function Assert-TestPublicDocsUrlExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$DocsRoot
    )

    $resolvedUrl = Resolve-TestPublicDocsUrl -Url $Url -DocsRoot $DocsRoot
    (Test-Path -LiteralPath $resolvedUrl.FilePath) | Should -BeTrue -Because "Expected docs page for $Url at $( $resolvedUrl.FilePath )"

    if (-not [string]::IsNullOrWhiteSpace($resolvedUrl.Anchor)) {
        $content = Get-Content -LiteralPath $resolvedUrl.FilePath -Raw
        $anchorPattern = 'id="{0}"' -f [regex]::Escape($resolvedUrl.Anchor)
        $content | Should -Match $anchorPattern -Because "Expected anchor #$( $resolvedUrl.Anchor ) in $( $resolvedUrl.FilePath ) for $Url"
    }

    return $resolvedUrl
}

