function Initialize-NovaPesterExecutionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$PesterConfig,
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [AllowNull()][hashtable]$ExecutionOption
    )

    $outputOptionOverrides = Get-NovaPesterOutputOptionOverride -PesterConfig $PesterConfig -BoundParameters $BoundParameters -OutputVerbosity (Get-NovaPesterOverrideValue -InputObject $ExecutionOption -Name 'OutputVerbosity') -OutputRenderMode (Get-NovaPesterOverrideValue -InputObject $ExecutionOption -Name 'OutputRenderMode')
    if ($null -ne $outputOptionOverrides) {
        if ($null -ne $outputOptionOverrides.Verbosity) {
            $PesterConfig.Output.Verbosity = $outputOptionOverrides.Verbosity
        }

        if ($null -ne $outputOptionOverrides.RenderMode) {
            $PesterConfig.Output.RenderMode = $outputOptionOverrides.RenderMode
        }
    }

    if ($PesterConfig.TestResult.PSObject.Properties.Name -contains 'Enabled') {
        $PesterConfig.TestResult.Enabled = $false
    }

    $pesterConfigurationOverride = Get-NovaPesterOverrideValue -InputObject $ExecutionOption -Name 'PesterConfigurationOverride'
    if ($null -ne $pesterConfigurationOverride) {
        Initialize-NovaPesterContainerOverride -PesterConfig $PesterConfig -PesterConfigurationOverride $pesterConfigurationOverride -ProjectRoot (Get-NovaPesterOverrideValue -InputObject $ExecutionOption -Name 'ProjectRoot')
    }
}

function Initialize-NovaPesterContainerOverride {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$PesterConfig,
        [Parameter(Mandatory)][object]$PesterConfigurationOverride,
        [string]$ProjectRoot
    )

    $overridePropertyNames = @(Get-NovaPesterOverridePropertyName -InputObject $PesterConfigurationOverride)
    if ($overridePropertyNames.Count -eq 0) {
        return
    }

    Assert-NovaAllowedPesterConfigurationOverridePath -PropertyName $overridePropertyNames -AllowedPropertyName 'Run' -Prefix ''
    $runOverride = Get-NovaPesterOverrideValue -InputObject $PesterConfigurationOverride -Name 'Run'
    $runPropertyNames = @(Get-NovaPesterOverridePropertyName -InputObject $runOverride)
    Assert-NovaAllowedPesterConfigurationOverridePath -PropertyName $runPropertyNames -AllowedPropertyName 'Container' -Prefix 'Run'

    $containerOverride = Get-NovaPesterOverrideValue -InputObject $runOverride -Name 'Container'
    if ($null -eq $containerOverride) {
        $containerOverride = @()
    }
    else {
        $containerOverride = @($containerOverride)
    }

    if ($containerOverride.Count -eq 0) {
        Stop-NovaOperation -Message "Invoke-NovaTest only supports PesterConfigurationOverride.Run.Container in v1. Provide one or more file-backed containers created with New-PesterContainer -Path." -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject 'PesterConfigurationOverride.Run.Container'
    }

    $resolvedRunPath = @(Get-NovaResolvedPesterOverridePathSet -Path (Get-NovaPesterOverridePathInput -Path $PesterConfig.Run.Path) -ProjectRoot $ProjectRoot)
    $providedContainerByPath = @{}
    foreach ($container in $containerOverride) {
        $resolvedContainerPath = Get-NovaValidatedPesterOverrideContainerPath -Container $container -ResolvedRunPath $resolvedRunPath -ProjectRoot $ProjectRoot
        if ($providedContainerByPath.ContainsKey($resolvedContainerPath)) {
            Stop-NovaOperation -Message "PesterConfigurationOverride.Run.Container cannot contain multiple containers for the same test path: $resolvedContainerPath" -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject $resolvedContainerPath
        }

        $providedContainerByPath[$resolvedContainerPath] = $container
    }

    $finalContainer = foreach ($path in $resolvedRunPath) {
        Resolve-NovaPesterContainerSelection -Path $path -ProvidedContainerByPath $providedContainerByPath
    }

    $PesterConfig.Run.Container = @($finalContainer)
    $PesterConfig.Run.Path = @()
}

function Resolve-NovaPesterContainerSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][hashtable]$ProvidedContainerByPath
    )

    if ($ProvidedContainerByPath.ContainsKey($Path)) {
        return $ProvidedContainerByPath[$Path]
    }

    return New-PesterContainer -Path $Path
}

function Assert-NovaAllowedPesterConfigurationOverridePath {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$PropertyName,
        [Parameter(Mandatory)][string]$AllowedPropertyName,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Prefix
    )

    foreach ($name in @($PropertyName | Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)})) {
        if ($name -eq $AllowedPropertyName) {
            continue
        }

        $path = @($Prefix, $name | Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)}) -join '.'
        Stop-NovaOperation -Message "Invoke-NovaTest only supports PesterConfigurationOverride.Run.Container in v1. Unsupported override path: $path" -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject $path
    }
}

function Get-NovaValidatedPesterOverrideContainerPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Container,
        [Parameter(Mandatory)][string[]]$ResolvedRunPath,
        [string]$ProjectRoot
    )

    $containerType = [string](Get-NovaPesterOverrideValue -InputObject $Container -Name 'Type')
    if ($containerType -ne 'File') {
        Stop-NovaOperation -Message "Invoke-NovaTest only supports file-backed PesterConfigurationOverride.Run.Container entries created with New-PesterContainer -Path. ScriptBlock and other container types are not supported." -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject $Container
    }

    $containerPath = [string](Get-NovaPesterOverrideValue -InputObject $Container -Name 'Item')
    if ([string]::IsNullOrWhiteSpace($containerPath)) {
        Stop-NovaOperation -Message 'PesterConfigurationOverride.Run.Container entries must expose a file path in the Item property.' -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject $Container
    }

    $resolvedContainerPath = Resolve-NovaPesterOverridePath -Path $containerPath -ProjectRoot $ProjectRoot
    if ($ResolvedRunPath -notcontains $resolvedContainerPath) {
        Stop-NovaOperation -Message "Invoke-NovaTest only accepts PesterConfigurationOverride.Run.Container entries for unit-test files discovered by Nova. Unsupported container path: $resolvedContainerPath" -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject $resolvedContainerPath
    }

    return $resolvedContainerPath
}

function Get-NovaResolvedPesterOverridePathSet {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][string[]]$Path,
        [string]$ProjectRoot
    )

    $resolvedPath = New-Object 'System.Collections.Generic.List[string]'
    foreach ($item in @($Path | Where-Object {-not [string]::IsNullOrWhiteSpace([string]$_)})) {
        $resolvedItem = Resolve-NovaPesterOverridePath -Path $item -ProjectRoot $ProjectRoot
        if (-not $resolvedPath.Contains($resolvedItem)) {
            $resolvedPath.Add($resolvedItem)
        }
    }

    return @($resolvedPath | Sort-Object)
}

function Get-NovaPesterOverridePathInput {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$Path
    )

    $pathValue = Get-NovaPesterOverrideValue -InputObject $Path -Name 'Value'
    if ($null -ne $pathValue) {
        return @($pathValue)
    }

    return @($Path)
}

function Resolve-NovaPesterOverridePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$ProjectRoot
    )

    $candidatePath = $Path
    if (-not [System.IO.Path]::IsPathRooted($candidatePath) -and -not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $candidatePath = Join-Path $ProjectRoot $candidatePath
    }

    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        Stop-NovaOperation -Message "PesterConfigurationOverride.Run.Container path does not exist: $candidatePath" -ErrorId 'Nova.Validation.UnsupportedPesterConfigurationOverride' -Category InvalidArgument -TargetObject $candidatePath
    }

    return (Resolve-Path -LiteralPath $candidatePath -ErrorAction Stop).Path
}

function Get-NovaPesterOverridePropertyName {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject
    )

    if ($null -eq $InputObject) {
        return @()
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        return @($InputObject.Keys)
    }

    return @($InputObject.PSObject.Properties.Name)
}

function Get-NovaPesterOverrideValue {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    if ($InputObject.PSObject.Properties.Name -contains $Name) {
        return $InputObject.$Name
    }

    return $null
}
