function Get-TestFrontMatterValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Key
    )

    $pattern = '(?m)^{0}:\s*(.+)$' -f [regex]::Escape($Key)
    if ($Content -match $pattern) {
        return $matches[1].Trim()
    }

    return $null
}

function Get-TestMarkdownSectionText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$SectionName
    )

    $pattern = '(?ms)^##\s+{0}\s*$\r?\n+(.*?)(?=^##\s+|\z)' -f [regex]::Escape($SectionName)
    if ($Content -match $pattern) {
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
                Get-TestFrontMatterValue -Content $content -Key 'Locale'
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
    $documentType = Get-TestFrontMatterValue -Content $content -Key 'document type'
    if ($documentType -ne 'cmdlet') {
        return $null
    }

    $helpTarget = Get-TestFrontMatterValue -Content $content -Key 'title'
    if ( [string]::IsNullOrWhiteSpace($helpTarget)) {
        $helpTarget = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    }

    return [pscustomobject]@{
        FileName = $File.Name
        HelpTarget = $helpTarget
        ExpectedSynopsis = ConvertTo-TestNormalizedText -Text (Get-TestMarkdownSectionText -Content $content -SectionName 'SYNOPSIS')
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

Export-ModuleMember -Function @(
    'Get-TestFrontMatterValue',
    'Get-TestMarkdownSectionText',
    'ConvertTo-TestNormalizedText',
    'Get-TestHelpLocaleFromMarkdownFiles',
    'Get-CommandHelpActivationTestCase',
    'Get-CommandHelpActivationTestCases'
)

