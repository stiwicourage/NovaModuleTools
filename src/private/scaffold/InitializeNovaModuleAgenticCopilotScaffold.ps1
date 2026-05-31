function Get-NovaModuleAgenticCopilotProjectShortName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer
    )

    if (-not $Answer.ContainsKey('ProjectShortName') -or [string]::IsNullOrWhiteSpace($Answer.ProjectShortName)) {
        Stop-NovaOperation -Message 'Project short name is required when Agentic Copilot setup is enabled.' -ErrorId 'Nova.Validation.AgenticCopilotProjectShortNameMissing' -Category InvalidData -TargetObject 'ProjectShortName'
    }

    return $Answer.ProjectShortName
}

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
        '{{ShortName}}' = Get-NovaModuleAgenticCopilotProjectShortName -Answer $Answer
        '{{ProjectDescription}}' = $description
        '{{StartHereBody}}' = @'
Use this repository as the starting point for your module.

- Review `README.md`, `CONTRIBUTING.md`, and `.github/copilot-instructions.md`.
- Use `Invoke-NovaBuild` / `% nova build` to produce the first local build.
- Use `Invoke-NovaTest` / `% nova test` for unit tests and `Test-NovaBuild` / `% nova test --build` for build-validation integration tests before opening a pull request.
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

function Test-NovaModuleAgenticCopilotTemplateFileEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][string]$RelativePath,
        [switch]$Example
    )

    if (-not $RelativePath.StartsWith('tests/', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }

    if ($Example) {
        return $true
    }

    return $Answer.ContainsKey('EnablePester') -and $Answer.EnablePester -eq 'Yes'
}

function Test-NovaModuleAgenticCopilotPathMatchesPolicyEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$Entry
    )

    if ( $Entry.EndsWith('/', [System.StringComparison]::Ordinal)) {
        return $RelativePath.StartsWith($Entry, [System.StringComparison]::OrdinalIgnoreCase)
    }

    return $RelativePath.Equals($Entry, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-NovaModuleAgenticCopilotPathMatchesPolicyList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [string[]]$EntryList = @()
    )

    foreach ($entry in @($EntryList)) {
        if (Test-NovaModuleAgenticCopilotPathMatchesPolicyEntry -RelativePath $RelativePath -Entry $entry) {
            return $true
        }
    }

    return $false
}

function Get-NovaModuleAgenticCopilotDestinationWriteMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [AllowNull()][pscustomobject]$ScaffoldPolicy
    )

    if ($null -eq $ScaffoldPolicy) {
        return 'Overwrite'
    }

    if (Test-NovaModuleAgenticCopilotPathMatchesPolicyList -RelativePath $RelativePath -EntryList $ScaffoldPolicy.ManagedOverwritePathList) {
        return 'Overwrite'
    }

    if (Test-NovaModuleAgenticCopilotPathMatchesPolicyList -RelativePath $RelativePath -EntryList $ScaffoldPolicy.AddOnlyPathList) {
        return 'AddIfMissing'
    }

    return 'Skip'
}

function Test-NovaModuleAgenticCopilotShouldWriteDestinationFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$WriteMode
    )

    if ($WriteMode -eq 'Overwrite') {
        return $true
    }

    if ($WriteMode -eq 'AddIfMissing') {
        return -not (Test-Path -LiteralPath $DestinationPath)
    }

    return $false
}

function ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Content
    )

    if ($null -eq $Content -or $Content.Length -eq 0) {
        return $Content
    }

    $trimmedContent = $Content.TrimEnd([char[]]@([char]13, [char]10))
    if ($trimmedContent.Length -eq 0) {
        return $Content
    }

    $lineEnding = if ( $Content.Contains("`r`n")) {
        "`r`n"
    } else {
        "`n"
    }

    return $trimmedContent + $lineEnding
}

function Get-NovaModuleAgenticCopilotDestinationContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][string]$TemplateContent,
        [Parameter(Mandatory)][System.Collections.IDictionary]$ScaffoldContext
    )

    if ($RelativePath -eq 'README.md') {
        return Get-NovaModuleAgenticCopilotReadmeContent -TemplateContent $TemplateContent -TokenMap $ScaffoldContext['TokenMap'] -ProjectRoot $ScaffoldContext['ProjectRoot'] -Example:([bool]$ScaffoldContext['Example'])
    }

    return Expand-NovaModuleAgenticCopilotTemplateContent -Content $TemplateContent -TokenMap $ScaffoldContext['TokenMap']
}

function Write-NovaModuleAgenticCopilotDestinationFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$Content
    )

    $destinationDirectory = Split-Path -Parent $DestinationPath
    if (-not (Test-Path -LiteralPath $destinationDirectory)) {
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    }

    $normalizedContent = ConvertTo-NovaModuleAgenticCopilotNormalizedFileContent -Content $Content
    Set-Content -LiteralPath $DestinationPath -Value $normalizedContent -Encoding utf8 -NoNewline
}

function Initialize-NovaModuleAgenticCopilotScaffold {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Answer,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [switch]$Example,
        [AllowNull()][pscustomobject]$ScaffoldPolicy = $null
    )

    $templateRoot = Get-NovaModuleAgenticCopilotTemplateRoot
    $tokenMap = Get-NovaModuleAgenticCopilotTemplateTokenMap -Answer $Answer
    $scaffoldContext = [ordered]@{
        TokenMap = $tokenMap
        ProjectRoot = $ProjectRoot
        Example = [bool]$Example
    }
    $templateFileList = @(Get-ChildItem -LiteralPath $templateRoot -File -Recurse -Force | Sort-Object FullName)

    foreach ($templateFile in $templateFileList) {
        $relativePath = Get-NormalizedRelativePath -Root $templateRoot -FullName $templateFile.FullName
        if (-not (Test-NovaModuleAgenticCopilotTemplateFileEnabled -Answer $Answer -RelativePath $relativePath -Example:$Example)) {
            continue
        }

        $destinationPath = Join-Path $ProjectRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)
        $writeMode = Get-NovaModuleAgenticCopilotDestinationWriteMode -RelativePath $relativePath -ScaffoldPolicy $ScaffoldPolicy
        if (-not (Test-NovaModuleAgenticCopilotShouldWriteDestinationFile -DestinationPath $destinationPath -WriteMode $writeMode)) {
            continue
        }

        $templateContent = Get-Content -LiteralPath $templateFile.FullName -Raw
        $destinationContent = Get-NovaModuleAgenticCopilotDestinationContent -RelativePath $relativePath -TemplateContent $templateContent -ScaffoldContext $scaffoldContext
        Write-NovaModuleAgenticCopilotDestinationFile -DestinationPath $destinationPath -Content $destinationContent
    }
}
