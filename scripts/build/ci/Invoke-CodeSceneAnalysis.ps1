param(
    [string]$CoveragePath,
    [switch]$UploadCoverage,
    [switch]$TriggerAnalysis
)

Set-StrictMode -Version Latest

function Get-RequiredCodeSceneValue {
    param([Parameter(Mandatory)][string]$Name)

    $value = [Environment]::GetEnvironmentVariable($Name)
    if ( [string]::IsNullOrWhiteSpace($value)) {
        throw "Missing required CodeScene configuration value '$Name'. Configure it as a CI secret or environment variable before running the analysis step."
    }

    return $value
}

function Test-CodeSceneRateLimitResponse {
    param([string]$Body)

    return $Body -match 'rate limit for daily analysis jobs'
}

function Test-CodeSceneInvalidProjectOwnerTokenResponse {
    param([string]$Body)

    return $Body -match 'OAuth token of project owner invalid'
}

function Get-CodeSceneAnalysisTriggerFailureMessage {
    param(
        [int]$StatusCode,
        [string]$Body
    )

    if (Test-CodeSceneInvalidProjectOwnerTokenResponse -Body $Body) {
        return "CodeScene rejected the analysis trigger because the project owner's repository OAuth token is invalid. Re-authorize the repository connection for the CodeScene project owner, then rerun the workflow. This is separate from CS_ACCESS_TOKEN, so coverage upload can still succeed while run-analysis fails."
    }

    return "CodeScene API call failed with HTTP $StatusCode. Review the response above for details."
}

function Test-CodeSceneCoverageUploadRequested {
    param(
        [string]$CoveragePath,
        [switch]$UploadCoverage
    )

    return $UploadCoverage.IsPresent -or -not [string]::IsNullOrWhiteSpace($CoveragePath)
}

function Resolve-CodeSceneCoveragePath {
    param([string]$CoveragePath)

    if (-not [string]::IsNullOrWhiteSpace($CoveragePath)) {
        return (Resolve-Path -LiteralPath $CoveragePath -ErrorAction Stop).Path
    }

    $defaultPath = Join-Path (Get-Location) 'artifacts' 'coverage.xml'
    if (-not (Test-Path -LiteralPath $defaultPath)) {
        throw "No JaCoCo coverage file was found at '$defaultPath'. Provide -CoveragePath explicitly or run the CI coverage workflow first."
    }

    return $defaultPath
}

function Invoke-CodeSceneAnalysisTrigger {
    param(
        [Parameter(Mandatory)][string]$CodeSceneUrl,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$AccessToken
    )

    $endpoint = '{0}/v2/projects/{1}/run-analysis' -f $CodeSceneUrl.TrimEnd('/'), $ProjectId
    Write-Host "Triggering CodeScene analysis: $endpoint"

    $response = Invoke-WebRequest -Uri $endpoint -Method Post -Headers @{
        Accept = 'application/json'
        Authorization = "Bearer $AccessToken"
    } -SkipHttpErrorCheck -ErrorAction Stop

    $statusCode = [int]$response.StatusCode
    $body = '' + $response.Content
    Write-Host "CodeScene HTTP status: $statusCode"
    if (-not [string]::IsNullOrWhiteSpace($body)) {
        Write-Host 'CodeScene response:'
        Write-Host $body
    }

    if ($statusCode -lt 200 -or $statusCode -ge 300) {
        if (Test-CodeSceneRateLimitResponse -Body $body) {
            Write-Warning "CodeScene analysis rate limit reached; skipping analysis trigger (HTTP $statusCode)."
            return
        }

        throw (Get-CodeSceneAnalysisTriggerFailureMessage -StatusCode $statusCode -Body $body)
    }

    if ($body -match '"error"') {
        throw 'CodeScene API returned an error payload despite a successful HTTP status.'
    }
}

function Repair-PesterJaCoCoCoveragePath {
    param([Parameter(Mandatory)][string]$Path)

    [xml]$document = Get-Content -LiteralPath $Path -Raw
    $changed = Repair-CodeSceneJaCoCoNodePathAttribute -Nodes $document.SelectNodes('//class[@sourcefilename]') -AttributeName 'sourcefilename'
    $changed = (Repair-CodeSceneJaCoCoNodePathAttribute -Nodes $document.SelectNodes('//sourcefile[@name]') -AttributeName 'name') -or $changed

    if ($changed) {
        $document.Save($Path)
        Write-Host "Normalized JaCoCo sourcefile paths in '$Path' so package + sourcefile resolve to repo files."
    }
}

function Repair-CodeSceneJaCoCoNodePathAttribute {
    param(
        [Parameter(Mandatory)]$Nodes,
        [Parameter(Mandatory)][string]$AttributeName
    )

    $changed = $false
    foreach ($node in $Nodes) {
        $changed = (Repair-CodeSceneJaCoCoNodeFileName -Node $node -AttributeName $AttributeName) -or $changed
    }

    return $changed
}

function Repair-CodeSceneJaCoCoNodeFileName {
    param(
        [Parameter(Mandatory)]$Node,
        [Parameter(Mandatory)][string]$AttributeName
    )

    $original = $Node.GetAttribute($AttributeName)
    $normalized = [System.IO.Path]::GetFileName($original)
    if ($normalized -eq $original) {
        return $false
    }

    $Node.SetAttribute($AttributeName, $normalized)
    return $true
}

function Test-JaCoCoBranchCoverageAvailable {
    param([Parameter(Mandatory)][string]$Path)

    [xml]$document = Get-Content -LiteralPath $Path -Raw
    return $null -ne $document.SelectSingleNode('//counter[@type="BRANCH"]')
}

$shouldUploadCoverage = Test-CodeSceneCoverageUploadRequested -CoveragePath $CoveragePath -UploadCoverage:$UploadCoverage
$shouldRunAnalysis = $TriggerAnalysis.IsPresent

if (-not ($shouldUploadCoverage -or $shouldRunAnalysis)) {
    Write-Host 'No CodeScene action requested. Provide -CoveragePath to upload coverage and/or -TriggerAnalysis to trigger analysis.'
    return
}

$codeSceneUrl = Get-RequiredCodeSceneValue -Name 'CS_URL'
$projectId = Get-RequiredCodeSceneValue -Name 'CS_PROJECT_ID'
$accessToken = Get-RequiredCodeSceneValue -Name 'CS_ACCESS_TOKEN'

if ($shouldUploadCoverage) {
    $resolvedCoveragePath = Resolve-CodeSceneCoveragePath -CoveragePath $CoveragePath
    Repair-PesterJaCoCoCoveragePath -Path $resolvedCoveragePath

    if (-not (Get-Command -Name 'cs-coverage' -ErrorAction SilentlyContinue)) {
        throw "The 'cs-coverage' CLI was not found on PATH. Install the CodeScene coverage upload tool before running this script."
    }

    & cs-coverage upload --format 'jacoco' --metric 'line-coverage' $resolvedCoveragePath
    if ($LASTEXITCODE -ne 0) {
        throw "CodeScene line-coverage upload failed with exit code $LASTEXITCODE."
    }

    if (Test-JaCoCoBranchCoverageAvailable -Path $resolvedCoveragePath) {
        & cs-coverage upload --format 'jacoco' --metric 'branch-coverage' $resolvedCoveragePath
        if ($LASTEXITCODE -ne 0) {
            throw "CodeScene branch-coverage upload failed with exit code $LASTEXITCODE."
        }
    }
    else {
        Write-Host "Skipping branch-coverage upload: '$resolvedCoveragePath' does not contain <counter type=`"BRANCH`"> entries."
    }
}

if ($shouldRunAnalysis) {
    Invoke-CodeSceneAnalysisTrigger -CodeSceneUrl $codeSceneUrl -ProjectId $projectId -AccessToken $accessToken
}
