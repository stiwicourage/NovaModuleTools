function Build-Module {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo
    $novaBuildVersion = (Get-Command Invoke-NovaBuild).Version
    Write-Verbose "Running NovaModuleTools Version: $novaBuildVersion"
    Write-Verbose 'Buidling module psm1 file'
    Test-ProjectSchema -Schema Build | Out-Null

    $sb = [System.Text.StringBuilder]::new()
    Add-ProjectPreambleToModuleBuilder -Builder $sb -ProjectInfo $data

    $files = @(Get-ProjectScriptFile -ProjectInfo $data)
    $allSourceFiles = @(
        Get-ChildItem -Path $data.ClassesDir, $data.PublicDir, $data.PrivateDir -Filter '*.ps1' -File -Recurse -ErrorAction SilentlyContinue
    )

    if ($files.Count -eq 0 -and $allSourceFiles.Count -eq 0) {
        Stop-NovaOperation -Message 'No source files found to build. Add one or more scripts under src/public, src/private, or src/classes.' -ErrorId 'Nova.Environment.BuildSourceFilesNotFound' -Category ObjectNotFound -TargetObject 'src'
    }

    foreach ($file in $files) {
        Add-ScriptFileContentToModuleBuilder -Builder $sb -ProjectInfo $data -File $file
    }
    try {
        Set-Content -Path $data.ModuleFilePSM1 -Value $sb.ToString() -Encoding 'UTF8' # psm1 file
    } catch {
        Stop-NovaOperation -Message ('Failed to create psm1 file: {0}' -f $_.Exception.Message) -ErrorId 'Nova.Dependency.ModulePsm1CreationFailed' -Category OpenError -TargetObject $data.ModuleFilePSM1
    }
}
