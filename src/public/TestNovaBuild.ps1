function Test-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string[]]$TagFilter,
        [string[]]$ExcludeTagFilter,
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string]$OutputVerbosity,
        [ValidateSet('Auto', 'Plaintext', 'Ansi')]
        [string]$OutputRenderMode
    )
    Test-ProjectSchema Pester | Out-Null
    $Script:data = Get-NovaProjectInfo
    $pesterConfig = New-PesterConfiguration -Hashtable $data.Pester

    $testPath = if ($data.BuildRecursiveFolders) {
        $data.TestsDir
    }
    else {
        [System.IO.Path]::Join($data.TestsDir, '*.Tests.ps1')
    }

    $pesterConfig.Run.Path = $testPath
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Run.Exit = $true
    $pesterConfig.Run.Throw = $true
    $pesterConfig.Filter.Tag = $TagFilter
    $pesterConfig.Filter.ExcludeTag = $ExcludeTagFilter
    $outputOptionOverrides = Get-NovaPesterOutputOptionOverride -PesterConfig $pesterConfig -BoundParameters $PSBoundParameters -OutputVerbosity $OutputVerbosity -OutputRenderMode $OutputRenderMode
    if ($null -ne $outputOptionOverrides) {
        if ($null -ne $outputOptionOverrides.Verbosity) {
            $pesterConfig.Output.Verbosity = $outputOptionOverrides.Verbosity
        }

        $pesterConfig.Output.RenderMode = $outputOptionOverrides.RenderMode
    }

    if ($pesterConfig.TestResult.PSObject.Properties.Name -contains 'Enabled') {
        $pesterConfig.TestResult.Enabled = $false
    }

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
    $TestResult = Invoke-NovaPesterWithPlainTextOutput -Configuration $pesterConfig
    & $testResultArtifactWriter.ScriptBlock -TestResult $TestResult -OutputPath $testResultPath -ReportWriter $testResultReportWriter.ScriptBlock

    if ($TestResult.Result -ne 'Passed') {
        throw 'Tests failed'
        return $LASTEXITCODE
    }
}
