function Get-TestRegexMatchGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Pattern
    )

    if ($Content -match $Pattern) {
        return $matches[1].Trim()
    }

    return $null
}

function ConvertTo-TestNormalizedText {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text
    )

    if ( [string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    return ($Text -replace '\s+', ' ').Trim()
}

function Get-TestHelpLocaleFromMarkdownFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo[]]$Files
    )

    $locales = @(
    $Files |
            ForEach-Object {
                $content = Get-Content -LiteralPath $_.FullName -Raw
                $pattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape('Locale')
                Get-TestRegexMatchGroup -Content $content -Pattern $pattern
            } |
            Where-Object {-not [string]::IsNullOrWhiteSpace($_)} |
            Select-Object -Unique
    )

    if ($locales.Count -gt 1) {
        throw "Multiple help locales found in docs metadata: $( $locales -join ', ' )"
    }

    if ($locales.Count -eq 1) {
        return $locales[0]
    }

    return 'en-US'
}

function Get-CommandHelpActivationTestCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$File
    )

    $content = Get-Content -LiteralPath $File.FullName -Raw
    $documentTypePattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape('document type')
    $documentType = Get-TestRegexMatchGroup -Content $content -Pattern $documentTypePattern
    if ($documentType -ne 'cmdlet') {
        return $null
    }

    $titlePattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape('title')
    $helpTarget = Get-TestRegexMatchGroup -Content $content -Pattern $titlePattern
    if ( [string]::IsNullOrWhiteSpace($helpTarget)) {
        $helpTarget = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    }

    $synopsisPattern = '(?ms)^##\s+{0}\s*$\r?\n+(.*?)(?=^##\s+|\z)' -f [regex]::Escape('SYNOPSIS')

    return [pscustomobject]@{
        FileName = $File.Name
        HelpTarget = $helpTarget
        ExpectedSynopsis = ConvertTo-TestNormalizedText -Text (Get-TestRegexMatchGroup -Content $content -Pattern $synopsisPattern)
    }
}

function Get-CommandHelpActivationTestCases {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DocsDir
    )

    $helpMarkdownFiles = Get-ChildItem -LiteralPath $DocsDir -Filter '*.md' -Recurse
    return @(
    $helpMarkdownFiles |
            ForEach-Object {Get-CommandHelpActivationTestCase -File $_} |
            Where-Object {$_}
    )
}

function Assert-TestPowerShellHelpExcludesCliSyntax {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory)][string]$Subject
    )

    if ( [string]::IsNullOrWhiteSpace($Text)) {
        return
    }

    foreach ($forbiddenPattern in @(
        [pscustomobject]@{
            Pattern = '(?-i)\bnova\s+(?:--help|--version|info|version|build|test|package|deploy|init|bump|update|notification|publish|release)\b'
            Reason = 'should not mention launcher command syntax'
        }
        [pscustomobject]@{
            Pattern = '(?<![A-Za-z0-9-])--[a-z][a-z-]*'
            Reason = 'should not expose GNU-style long options'
        }
        [pscustomobject]@{
            Pattern = '(?m)^\s*[%$]\s*nova\b'
            Reason = 'should not include shell prompt launcher examples'
        }
    )) {
        $Text | Should -Not -Match $forbiddenPattern.Pattern -Because "$Subject $( $forbiddenPattern.Reason )"
    }
}
