function Get-NovaGitIgnoreManagedLineList {
    [CmdletBinding()]
    param()

    return @(
        '# CI/local test artifacts'
        'testResults.xml'
        'coverage.xml'
        'artifacts/'
        'dist/'
        'run.ps1'
        'reload.ps1'
    )
}

function Get-NovaGitIgnoreLineList {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Content
    )

    if ( [string]::IsNullOrEmpty($Content)) {
        return @()
    }

    $lineList = [System.Collections.Generic.List[string]]::new()
    foreach ($line in [regex]::Split($Content, '\r?\n')) {
        $lineList.Add($line)
    }

    while ($lineList.Count -gt 0 -and $lineList[$lineList.Count - 1] -eq '') {
        $lineList.RemoveAt($lineList.Count - 1)
    }

    return @($lineList)
}

function ConvertTo-NovaGitIgnoreContent {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$LineList = @()
    )

    if (@($LineList).Count -eq 0) {
        return ''
    }

    return (@($LineList) -join [Environment]::NewLine) + [Environment]::NewLine
}

function Get-NovaGitIgnoreLineListToAppend {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$ExistingLineList
    )

    $managedLineList = Get-NovaGitIgnoreManagedLineList
    $commentLine = $managedLineList[0]
    $managedArtifactLineList = @($managedLineList[1..($managedLineList.Count - 1)])
    $missingArtifactLineList = @($managedArtifactLineList | Where-Object {$ExistingLineList -notcontains $_})
    if ($missingArtifactLineList.Count -eq 0) {
        return @()
    }

    if ($ExistingLineList -contains $commentLine) {
        return $missingArtifactLineList
    }

    return @($commentLine) + $missingArtifactLineList
}

function Get-NovaGitIgnoreUpdatedContent {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$ExistingContent
    )

    $existingLineList = Get-NovaGitIgnoreLineList -Content $ExistingContent
    $lineListToAppend = @(Get-NovaGitIgnoreLineListToAppend -ExistingLineList $existingLineList)
    if ($lineListToAppend.Count -eq 0) {
        return $null
    }

    $updatedLineList = [System.Collections.Generic.List[string]]::new()
    foreach ($existingLine in $existingLineList) {
        $updatedLineList.Add($existingLine)
    }

    if ($updatedLineList.Count -gt 0) {
        $updatedLineList.Add('')
    }

    foreach ($lineToAppend in $lineListToAppend) {
        $updatedLineList.Add($lineToAppend)
    }

    return ConvertTo-NovaGitIgnoreContent -LineList $updatedLineList
}

function Update-NovaGitIgnore {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $gitIgnorePath = Join-Path $ProjectRoot '.gitignore'
    if (-not (Test-Path -LiteralPath $gitIgnorePath -PathType Leaf)) {
        if (-not $PSCmdlet.ShouldProcess($gitIgnorePath, 'Create default .gitignore')) {
            return
        }

        $content = ConvertTo-NovaGitIgnoreContent -LineList (Get-NovaGitIgnoreManagedLineList)
        Set-Content -LiteralPath $gitIgnorePath -Value $content -Encoding utf8 -NoNewline
        return
    }

    $existingContent = Get-Content -LiteralPath $gitIgnorePath -Raw
    $updatedContent = Get-NovaGitIgnoreUpdatedContent -ExistingContent $existingContent
    if ($null -eq $updatedContent) {
        return
    }

    if (-not $PSCmdlet.ShouldProcess($gitIgnorePath, 'Append missing default .gitignore entries')) {
        return
    }

    Set-Content -LiteralPath $gitIgnorePath -Value $updatedContent -Encoding utf8 -NoNewline
}

