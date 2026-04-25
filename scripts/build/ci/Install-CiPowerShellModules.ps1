param(
    [string[]]$ModuleName = @(
    'NovaModuleTools'
)
)

Set-StrictMode -Version Latest

function Remove-CiLoadedModule {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $loadedModuleList = @(Get-Module -Name $Name -All)
    if ($loadedModuleList.Count -eq 0) {
        return
    }

    Write-Host "Removing loaded PowerShell module '$Name' before installation..."
    if (-not $PSCmdlet.ShouldProcess($Name, 'Remove loaded PowerShell module from current session')) {
        return
    }

    $loadedModuleList | Remove-Module -Force -ErrorAction SilentlyContinue
}

function Get-CiPreUnloadModuleNameList {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    $moduleNameList = [System.Collections.Generic.List[string]]::new()
    $moduleNameList.Add($Name)

    if ($Name -eq 'NovaModuleTools') {
        $moduleNameList.Add('Pester')
        $moduleNameList.Add('Microsoft.PowerShell.PlatyPS')
    }

    return @($moduleNameList | Select-Object -Unique)
}

function Install-CiModule {
    param(
        [Parameter(Mandatory)][string]$Name
    )

    Write-Host "Installing PowerShell module '$Name'..."

    foreach ($moduleName in (Get-CiPreUnloadModuleNameList -Name $Name)) {
        Remove-CiLoadedModule -Name $moduleName
    }

    Install-Module -Name $Name -AllowPrerelease -Scope CurrentUser -Force -ErrorAction Stop | Out-Null

    $installedModule = Get-InstalledModule -Name $Name -ErrorAction Stop |
            Sort-Object Version -Descending |
            Select-Object -First 1

    Write-Host "Installed PowerShell module '$( $installedModule.Name )' version '$( $installedModule.Version )' from '$( $installedModule.Repository )'."
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

foreach ($name in $ModuleName) {
    Install-CiModule -Name $name
}
