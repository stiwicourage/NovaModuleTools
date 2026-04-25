function Get-TestModuleDisplayVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Module
    )

    $versionText = $Module.Version.ToString()
    $prereleaseLabel = $null
    $psData = $Module.PrivateData.PSData

    if ($psData -is [hashtable]) {
        $prereleaseLabel = $psData['Prerelease']
    }
    elseif ($null -ne $psData -and $psData.PSObject.Properties.Name -contains 'Prerelease') {
        $prereleaseLabel = $psData.Prerelease
    }

    if ( [string]::IsNullOrWhiteSpace($prereleaseLabel)) {
        return $versionText
    }

    return "$versionText-$prereleaseLabel"
}

function Publish-TestSupportFunctions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$FunctionNameList
    )

    foreach ($functionName in $FunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }
}

function Assert-TestModuleIsBuilt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ModuleName,
        [Parameter(Mandatory)][string]$ModuleDirectory
    )

    if (-not (Test-Path -LiteralPath $ModuleDirectory)) {
        throw "Expected built $ModuleName module at: $ModuleDirectory. Run Invoke-NovaBuild in the repo root first."
    }
}

function Get-TestModuleContextInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CommandPath
    )

    $testsRoot = Split-Path -Parent $CommandPath
    $repoRoot = Split-Path -Parent $testsRoot
    $moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName

    return [pscustomobject]@{
        ModuleName = $moduleName
        DistModuleDir = Join-Path $repoRoot "dist/$moduleName"
    }
}

function Initialize-TestModuleContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CommandPath,
        [Parameter(Mandatory)][string]$SupportPath,
        [Parameter(Mandatory)][string[]]$FunctionNameList
    )

    $context = Get-TestModuleContextInfo -CommandPath $CommandPath
    Assert-TestModuleIsBuilt -ModuleName $context.ModuleName -ModuleDirectory $context.DistModuleDir
    Remove-Module $context.ModuleName -ErrorAction SilentlyContinue
    Import-Module $context.DistModuleDir -Force
    . $SupportPath
    Publish-TestSupportFunctions -FunctionNameList $FunctionNameList

    return $context
}

