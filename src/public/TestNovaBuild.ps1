function Test-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string[]]$TagFilter,
        [string[]]$ExcludeTagFilter,
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string]$OutputVerbosity,
        [ValidateSet('Auto', 'Ansi')]
        [string]$OutputRenderMode
    )
    Test-ProjectSchema Pester | Out-Null
    $Script:data = Get-NovaProjectInfo
    $pesterConfig = New-PesterConfiguration -Hashtable $data.Pester

    $pesterConfig.Run.Path = Get-NovaPesterRunPath -ProjectInfo $data
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.Run.Throw = $true
    $pesterConfig.Filter.Tag = $TagFilter
    $pesterConfig.Filter.ExcludeTag = $ExcludeTagFilter
    Initialize-NovaPesterExecutionConfiguration -PesterConfig $pesterConfig -BoundParameters $PSBoundParameters -OutputVerbosity $OutputVerbosity -OutputRenderMode $OutputRenderMode

    $testResultPath = Get-NovaPesterTestResultPath -ProjectRoot $data.ProjectRoot
    $testResultDirectory = Split-Path -Parent $testResultPath

    if (-not $PSCmdlet.ShouldProcess($testResultPath, 'Run Pester tests and write test results')) {
        return
    }

    if (-not (Test-Path -LiteralPath $testResultDirectory)) {
        $null = New-Item -ItemType Directory -Path $testResultDirectory -Force
    }

    $testResultArtifactWriter = Get-Command -Name Write-NovaPesterTestResultArtifact -CommandType Function -ErrorAction Stop
    $testResultReportWriter = Get-Command -Name Write-NovaPesterTestResultReport -CommandType Function -ErrorAction Stop
    $pesterConfig.TestResult.OutputPath = $testResultPath
    $TestResult = Invoke-NovaPester -Configuration $pesterConfig
    & $testResultArtifactWriter.ScriptBlock -TestResult $TestResult -OutputPath $testResultPath -ReportWriter $testResultReportWriter.ScriptBlock

    if ($TestResult.Result -ne 'Passed') {
        throw 'Tests failed'
        return $LASTEXITCODE
    }
}
