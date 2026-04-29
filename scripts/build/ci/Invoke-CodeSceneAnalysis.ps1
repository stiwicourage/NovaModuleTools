param(
    [string]$CoveragePath,
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

        throw "CodeScene API call failed with HTTP $statusCode. Review the response above for details."
    }

    if ($body -match '"error"') {
        throw 'CodeScene API returned an error payload despite a successful HTTP status.'
    }
}

$shouldUploadCoverage = -not [string]::IsNullOrWhiteSpace($CoveragePath)
$shouldRunAnalysis = $TriggerAnalysis.IsPresent

if (-not ($shouldUploadCoverage -or $shouldRunAnalysis)) {
    Write-Host 'No CodeScene action requested. Provide -CoveragePath to upload coverage and/or -TriggerAnalysis to trigger analysis.'
    return
}

$codeSceneUrl = Get-RequiredCodeSceneValue -Name 'CS_URL'
$projectId = Get-RequiredCodeSceneValue -Name 'CS_PROJECT_ID'
$accessToken = Get-RequiredCodeSceneValue -Name 'CS_ACCESS_TOKEN'

if ($shouldUploadCoverage) {
    $resolvedCoveragePath = (Resolve-Path -LiteralPath $CoveragePath -ErrorAction Stop).Path

    if (-not (Get-Command -Name 'cs-coverage' -ErrorAction SilentlyContinue)) {
        throw "The 'cs-coverage' CLI was not found on PATH. Install the CodeScene coverage upload tool before running this script."
    }

    & cs-coverage upload --format 'cobertura' --metric 'line-coverage' $resolvedCoveragePath
    if ($LASTEXITCODE -ne 0) {
        throw "CodeScene coverage upload failed with exit code $LASTEXITCODE."
    }
}

if ($shouldRunAnalysis) {
    Invoke-CodeSceneAnalysisTrigger -CodeSceneUrl $codeSceneUrl -ProjectId $projectId -AccessToken $accessToken
}
