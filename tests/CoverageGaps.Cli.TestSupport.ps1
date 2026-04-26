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

function Get-TestNovaCliRoutedParserCaseList {
    return @(
        @{
            ParserCommand = 'ConvertFrom-NovaBuildCliArgument'
            ValidCases = @(
                @{Arguments = @('--continuous-integration'); Property = 'ContinuousIntegration'}
                @{Arguments = @('-i'); Property = 'ContinuousIntegration'}
            )
        }
        @{
            ParserCommand = 'ConvertFrom-NovaBumpCliArgument'
            ValidCases = @(
                @{Arguments = @('--preview'); Property = 'Preview'}
                @{Arguments = @('-p'); Property = 'Preview'}
                @{Arguments = @('--continuous-integration'); Property = 'ContinuousIntegration'}
                @{Arguments = @('-i'); Property = 'ContinuousIntegration'}
            )
        }
        @{
            ParserCommand = 'ConvertFrom-NovaTestCliArgument'
            ValidCases = @(
                @{Arguments = @('--build'); Property = 'Build'}
                @{Arguments = @('-b'); Property = 'Build'}
            )
        }
    )
}

function Get-TestNovaCliContinuousIntegrationRouteCaseList {
    return @(
        @{Command = 'build'; ParserCommand = 'ConvertFrom-NovaBuildCliArgument'; ActionCommand = 'Invoke-NovaBuild'}
        @{Command = 'bump'; ParserCommand = 'ConvertFrom-NovaBumpCliArgument'; ActionCommand = 'Update-NovaModuleVersion'}
    )
}

function Get-TestNovaCliNormalizedRootCommandCaseList {
    return @(
        @{Command = '-h'; Expected = '--help'}
        @{Command = '-v'; Expected = '--version'}
        @{Command = 'build'; Expected = 'build'}
    )
}

function Get-TestNovaCliOptionClassificationCaseList {
    return @(
        @{HelperName = 'Test-NovaCliLegacySingleHyphenOption'; Argument = '-legacy'; Expected = $true}
        @{HelperName = 'Test-NovaCliLegacySingleHyphenOption'; Argument = '--legacy'; Expected = $false}
        @{HelperName = 'Test-NovaCliWhatIfOption'; Argument = '--what-if'; Expected = $true}
        @{HelperName = 'Test-NovaCliConfirmOption'; Argument = '-c'; Expected = $true}
    )
}

function Get-TestNovaCliSyntaxGuidanceCaseList {
    return @(
        @{Argument = '-legacy'; Message = "Unsupported CLI option syntax: -legacy. Use long options with '--' or single-character short options."}
        @{Argument = '--whatif'; Message = "Unsupported CLI option syntax: --whatif. Use '--what-if' or '-w' instead."}
        @{Argument = '-build'; Message = "Unsupported CLI option syntax: -build. Use '--build' or '-b' instead."}
        @{Argument = '-skiptests'; Message = "Unsupported CLI option syntax: -skiptests. Use '--skip-tests' or '-s' instead."}
        @{Argument = '-continuousintegration'; Message = "Unsupported CLI option syntax: -continuousintegration. Use '--continuous-integration' or '-i' instead."}
    )
}

