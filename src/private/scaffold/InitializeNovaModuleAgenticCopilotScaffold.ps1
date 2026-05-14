function Get-NovaModuleAgenticCopilotTemplateTokenMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer
    )

    $description = if ( [string]::IsNullOrWhiteSpace($Answer.Description)) {
        "$( $Answer.ProjectName ) is a PowerShell module project scaffolded with NovaModuleTools."
    } else {
        $Answer.Description.TrimEnd('. ') + '.'
    }

    return [ordered]@{
        '{{ProjectName}}' = $Answer.ProjectName
        '{{ProjectDescription}}' = $description
        '{{StartHereBody}}' = @'
Use this repository as the starting point for your module.

- Review `README.md`, `CONTRIBUTING.md`, and `.github/copilot-instructions.md`.
- Use `Invoke-NovaBuild` / `% nova build` to produce the first local build.
- Use `Test-NovaBuild` / `% nova test` before opening a pull request.
'@
    }
}

function Get-NovaModuleAgenticCopilotReadmeContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TemplateContent,
        [Parameter(Mandatory)][hashtable]$TokenMap,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$Example
    )

    if (-not $Example) {
        return Expand-NovaModuleAgenticCopilotTemplateContent -Content $TemplateContent -TokenMap $TokenMap
    }

    $existingReadmePath = Join-Path $ProjectRoot 'README.md'
    if (-not (Test-Path -LiteralPath $existingReadmePath)) {
        return Expand-NovaModuleAgenticCopilotTemplateContent -Content $TemplateContent -TokenMap $TokenMap
    }

    $existingReadmeContent = Get-Content -LiteralPath $existingReadmePath -Raw
    $headingIndex = $existingReadmeContent.IndexOf("`n## ")
    if ($headingIndex -lt 0) {
        return Expand-NovaModuleAgenticCopilotTemplateContent -Content $TemplateContent -TokenMap $TokenMap
    }

    $startHereBody = @'
The packaged example scaffold keeps its working sample source, tests, and package configuration so you can inspect and adapt a real Nova project layout.

'@ + $existingReadmeContent.Substring($headingIndex + 1).TrimStart()
    $mergedTokenMap = [ordered]@{}

    foreach ($entry in $TokenMap.GetEnumerator()) {
        $mergedTokenMap[$entry.Key] = $entry.Value
    }

    $mergedTokenMap['{{StartHereBody}}'] = $startHereBody
    return Expand-NovaModuleAgenticCopilotTemplateContent -Content $TemplateContent -TokenMap $mergedTokenMap
}

function Expand-NovaModuleAgenticCopilotTemplateContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][System.Collections.IDictionary]$TokenMap
    )

    $expandedContent = $Content
    foreach ($entry in $TokenMap.GetEnumerator()) {
        $expandedContent = $expandedContent.Replace([string]$entry.Key, [string]$entry.Value)
    }

    return $expandedContent
}

function Initialize-NovaModuleAgenticCopilotScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$Example
    )

    $templateRoot = Get-NovaModuleAgenticCopilotTemplateRoot
    $tokenMap = Get-NovaModuleAgenticCopilotTemplateTokenMap -Answer $Answer
    $templateFileList = @(Get-ChildItem -LiteralPath $templateRoot -File -Recurse -Force | Sort-Object FullName)

    foreach ($templateFile in $templateFileList) {
        $relativePath = Get-NormalizedRelativePath -Root $templateRoot -FullName $templateFile.FullName
        $destinationPath = Join-Path $ProjectRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $destinationDirectory = Split-Path -Parent $destinationPath
        if (-not (Test-Path -LiteralPath $destinationDirectory)) {
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        }

        $templateContent = Get-Content -LiteralPath $templateFile.FullName -Raw
        $destinationContent = if ($relativePath -eq 'README.md') {
            Get-NovaModuleAgenticCopilotReadmeContent -TemplateContent $templateContent -TokenMap $tokenMap -ProjectRoot $ProjectRoot -Example:$Example
        } else {
            Expand-NovaModuleAgenticCopilotTemplateContent -Content $templateContent -TokenMap $tokenMap
        }

        Set-Content -LiteralPath $destinationPath -Value $destinationContent -Encoding utf8
    }
}
