function Build-Module {
    $data = Get-NovaProjectInfo
    $novaBuildVersion = (Get-Command Invoke-NovaBuild).Version
    Write-Verbose "Running NovaModuleTools Version: $novaBuildVersion"
    Write-Verbose 'Buidling module psm1 file'
    Test-ProjectSchema -Schema Build | Out-Null

    $sb = [System.Text.StringBuilder]::new()
    Add-ProjectPreambleToModuleBuilder -Builder $sb -ProjectInfo $data

    $files = Get-ProjectScriptFile -ProjectInfo $data
    foreach ($file in $files) {
        Add-ScriptFileContentToModuleBuilder -Builder $sb -ProjectInfo $data -File $file
    }
    try {
        Set-Content -Path $data.ModuleFilePSM1 -Value $sb.ToString() -Encoding 'UTF8' -ErrorAction Stop # psm1 file
    } catch {
        Write-Error 'Failed to create psm1 file' -ErrorAction Stop
    }
}
