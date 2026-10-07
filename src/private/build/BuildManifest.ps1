function Build-Manifest {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    Write-Verbose 'Building psd1 data file Manifest'
    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo
    $exportDefinition = Get-ManifestExportDefinition -PublicDir $data.PublicDir
    $formatFiles = Get-ManifestResourceFilePath -ResourcesDir $data.ResourcesDir -CopyResourcesToModuleRoot:$data.CopyResourcesToModuleRoot -Filter '*Format.ps1xml'
    $typeFiles = Get-ManifestResourceFilePath -ResourcesDir $data.ResourcesDir -CopyResourcesToModuleRoot:$data.CopyResourcesToModuleRoot -Filter '*Types.ps1xml'

    $ManfiestAllowedParams = (Get-Command New-ModuleManifest).Parameters.Keys
    Assert-ManifestSchema -Manifest $data.Manifest -AllowedParameter $ManfiestAllowedParams
    $sv = [semver]$data.Version
    $ParmsManifest = @{
        Path = $data.ManifestFilePSD1
        Description = $data.Description
        FunctionsToExport = $exportDefinition.FunctionToExport
        AliasesToExport = $exportDefinition.AliasToExport
        RootModule = "$( $data.ProjectName ).psm1"
        ModuleVersion = [version]$sv
        FormatsToProcess = $formatFiles
        TypesToProcess = $typeFiles
    }

    ## Release lable
    if ($sv.PreReleaseLabel) {
        $ParmsManifest['Prerelease'] = $sv.PreReleaseLabel
    }

    Add-AllowedManifestParameterEntry -ManifestParameters $ParmsManifest -Manifest $data.Manifest -AllowedParameter $ManfiestAllowedParams

    try {
        New-ModuleManifest @ParmsManifest
    } catch {
        Stop-NovaOperation -Message ('Failed to create Manifest: {0}' -f $_.Exception.Message) -ErrorId 'Nova.Dependency.ModuleManifestCreationFailed' -Category OpenError -TargetObject $data.ManifestFilePSD1
    }

    if ($data.Manifest.Contains('PrivateData') -and $data.Manifest['PrivateData'] -is [System.Collections.IDictionary]) {
        Update-ManifestPrivateData -ManifestPath $data.ManifestFilePSD1 -PrivateData $data.Manifest['PrivateData']
        Assert-GeneratedManifestPrivateDataCanBeImported -ManifestPath $data.ManifestFilePSD1
    }
}

function Assert-GeneratedManifestPrivateDataCanBeImported {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ManifestPath
    )

    try {
        $null = Import-PowerShellDataFile -LiteralPath $ManifestPath -ErrorAction Stop
    } catch {
        Stop-NovaOperation -Message ('Generated manifest contains invalid PrivateData: {0}' -f $_.Exception.Message) -ErrorId 'Nova.Dependency.ModuleManifestPrivateDataValidationFailed' -Category InvalidData -TargetObject $ManifestPath
    }
}

function Get-ManifestExportDefinition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PublicDir
    )

    $functionToExport = @()
    $aliasToExport = @()
    foreach ($publicFunctionFile in @(Get-ChildItem -Path $PublicDir -Filter *.ps1)) {
        $functionToExport += Get-FunctionNameFromFile -filePath $publicFunctionFile.FullName
        $aliasToExport += Get-AliasInFunctionFromFile -filePath $publicFunctionFile.FullName
    }

    return [pscustomobject]@{
        FunctionToExport = $functionToExport
        AliasToExport = $aliasToExport
    }
}

function Get-ManifestResourceFilePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ResourcesDir,
        [Parameter(Mandatory)][string]$Filter,
        [switch]$CopyResourcesToModuleRoot
    )

    $resourceFilePath = @()
    Get-ChildItem -Path $ResourcesDir -File -Filter $Filter -ErrorAction SilentlyContinue | ForEach-Object {
        if ($CopyResourcesToModuleRoot) {
            $resourceFilePath += $_.Name
            return
        }

        $resourceFilePath += Join-Path -Path 'resources' -ChildPath $_.Name
    }

    return $resourceFilePath
}

function Add-AllowedManifestParameterEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ManifestParameters,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Manifest,
        [Parameter(Mandatory)][string[]]$AllowedParameter
    )

    foreach ($name in $Manifest.Keys) {
        if ($name -eq 'PrivateData' -or $AllowedParameter -notcontains $name) {
            continue
        }

        if ($Manifest.$name) {
            $ManifestParameters.add($name, $Manifest.$name)
        }
    }
}
