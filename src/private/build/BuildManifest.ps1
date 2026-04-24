function Build-Manifest {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    Write-Verbose 'Building psd1 data file Manifest'
    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo

    $PubFunctionFiles = @(Get-ChildItem -Path $data.PublicDir -Filter *.ps1)
    $functionToExport = @()
    $aliasToExport = @()
    foreach ($pubFunctionFile in $PubFunctionFiles) {
        $functionToExport += Get-FunctionNameFromFile -filePath $pubFunctionFile.FullName
        $aliasToExport += Get-AliasInFunctionFromFile -filePath $pubFunctionFile.FullName
    }

    ## Import Format.ps1xml (if any)
    $FormatsToProcess = @()
    Get-ChildItem -Path $data.ResourcesDir -File -Filter '*Format.ps1xml' -ErrorAction SilentlyContinue | ForEach-Object {
        if ($data.CopyResourcesToModuleRoot) {
            $FormatsToProcess += $_.Name
        } else {
            $FormatsToProcess += Join-Path -Path 'resources' -ChildPath $_.Name
        }
    }

    ## Import Types.ps1xml1 (if any)
    $TypesToProcess = @()
    Get-ChildItem -Path $data.ResourcesDir -File -Filter '*Types.ps1xml' -ErrorAction SilentlyContinue | ForEach-Object {
        if ($data.CopyResourcesToModuleRoot) {
            $TypesToProcess += $_.Name
        } else {
            $TypesToProcess += Join-Path -Path 'resources' -ChildPath $_.Name
        }
    }

    $ManfiestAllowedParams = (Get-Command New-ModuleManifest).Parameters.Keys
    Assert-ManifestSchema -Manifest $data.Manifest -AllowedParameter $ManfiestAllowedParams
    $sv = [semver]$data.Version
    $ParmsManifest = @{
        Path              = $data.ManifestFilePSD1
        Description       = $data.Description
        FunctionsToExport = $functionToExport
        AliasesToExport   = $aliasToExport
        RootModule        = "$($data.ProjectName).psm1"
        ModuleVersion     = [version]$sv
        FormatsToProcess  = $FormatsToProcess
        TypesToProcess    = $TypesToProcess
    }
      
    ## Release lable
    if ($sv.PreReleaseLabel) {
        $ParmsManifest['Prerelease'] = $sv.PreReleaseLabel 
    } 

    # Accept only valid Manifest Parameters
    $data.Manifest.Keys | ForEach-Object {
        if ( $ManfiestAllowedParams -contains $_) {
            if ($data.Manifest.$_) {
                $ParmsManifest.add($_, $data.Manifest.$_ )
            }
        }
    }

    try {
        New-ModuleManifest @ParmsManifest
    } catch {
        Stop-NovaOperation -Message ('Failed to create Manifest: {0}' -f $_.Exception.Message) -ErrorId 'Nova.Dependency.ModuleManifestCreationFailed' -Category OpenError -TargetObject $data.ManifestFilePSD1
    }
}
