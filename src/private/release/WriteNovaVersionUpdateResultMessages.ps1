function Invoke-NovaVersionUpdateCiActivation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][hashtable]$Parameters,
        [switch]$ContinuousIntegration,
        [switch]$WhatIfEnabled
    )

    if (-not $ContinuousIntegration -or $WhatIfEnabled) {
        return [pscustomobject]@{ShouldReturn = $false; Result = $null}
    }

    $ciActivatedCommand = Get-NovaVersionUpdateCiActivatedCommand -ProjectRoot $ProjectRoot
    if ($null -eq $ciActivatedCommand) {
        return [pscustomobject]@{ShouldReturn = $false; Result = $null}
    }

    return [pscustomobject]@{
        ShouldReturn = $true
        Result = & $ciActivatedCommand @Parameters
    }
}

function Write-NovaVersionUpdateResultOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    $advisoryMessage = Get-NovaVersionUpdateResultAdvisoryMessage -Result $Result
    if (-not [string]::IsNullOrWhiteSpace($advisoryMessage)) {
        Write-Warning $advisoryMessage
    }

    Write-Message (Get-NovaVersionUpdateResultStatusMessage -Result $Result) -color (Get-NovaVersionUpdateResultStatusColor -Result $Result)

    foreach ($line in (Get-NovaVersionUpdateResultDetailText -Result $Result)) {
        Write-Message $line
    }

    foreach ($line in (Get-NovaVersionUpdateResultNextStepText -Result $Result)) {
        Write-Message $line
    }
}

function Get-NovaVersionUpdateResultAdvisoryMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    return Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'AdvisoryMessage'
}

function Get-NovaVersionUpdateResultStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    if ([bool](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Cancelled')) {
        return 'Version update cancelled before changing project.json.'
    }

    if ([bool](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Previewed')) {
        return "Version update plan ready -> $( Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'NewVersion' )"
    }

    return "Updated project version to $( Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'NewVersion' )"
}

function Get-NovaVersionUpdateResultStatusColor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    if ([bool](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Cancelled')) {
        return 'Blue'
    }

    return 'Green'
}

function Get-NovaVersionUpdateResultDetailText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    $lines = @()
    $targetLine = Get-NovaVersionUpdateResultTargetLine -Result $Result
    if (-not [string]::IsNullOrWhiteSpace($targetLine)) {
        $lines += $targetLine
    }

    $lines += "Previous version: $( Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'PreviousVersion' )"
    $lines += "New version: $( Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'NewVersion' )"
    $lines += Get-NovaVersionUpdateResultLabelText -Result $Result

    $commitCount = Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'CommitCount'
    if ($null -ne $commitCount) {
        $lines += "Commits considered: $commitCount"
    }

    return $lines
}

function Get-NovaVersionUpdateResultTargetLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    $projectFile = Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'ProjectFile'
    if (-not [string]::IsNullOrWhiteSpace($projectFile)) {
        return "Version file: $projectFile"
    }

    $target = Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Target'
    if (-not [string]::IsNullOrWhiteSpace($target)) {
        return "Version file: $target"
    }

    return $null
}

function Get-NovaVersionUpdateResultLabelText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    $effectiveLabel = [string](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'EffectiveLabel')
    $detectedLabel = [string](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Label')
    if ($effectiveLabel -eq $detectedLabel) {
        return @("Release label: $effectiveLabel")
    }

    return @(
        "Detected release label: $detectedLabel"
        "Applied release label: $effectiveLabel"
    )
}

function Get-NovaVersionUpdateResultNextStepText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    if ([bool](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Cancelled')) {
        return @(
            'Next step:'
            'Run Update-NovaModuleVersion again when you are ready to write the new version to project.json.'
        )
    }

    if ([bool](Get-NovaVersionUpdateResultPropertyValue -Result $Result -Name 'Previewed')) {
        return @(
            'Next step:'
            'Run Update-NovaModuleVersion without -WhatIf when you are ready to apply the version change.'
        )
    }

    return @(
        'Next step:'
        'Invoke-NovaBuild'
    )
}

function Get-NovaVersionUpdateResultPropertyValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result,
        [Parameter(Mandatory)][string]$Name
    )

    $property = $Result.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}
