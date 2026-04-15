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
    if ( $PSBoundParameters.ContainsKey('OutputVerbosity')) {
        $pesterConfig.Output.Verbosity = $OutputVerbosity
    }

    if ( $PSBoundParameters.ContainsKey('OutputRenderMode')) {
        $pesterConfig.Output.RenderMode = $OutputRenderMode
    }

    $testResultPath = [System.IO.Path]::Join($data.ProjectRoot, 'artifacts', 'TestResults.xml')
    $testResultDirectory = Split-Path -Parent $testResultPath

    if (-not $PSCmdlet.ShouldProcess($testResultPath, 'Run Pester tests and write test results')) {
        return
    }

    if (-not (Test-Path -LiteralPath $testResultDirectory)) {
        $null = New-Item -ItemType Directory -Path $testResultDirectory -Force
    }

    $pesterConfig.TestResult.OutputPath = $testResultPath
    $TestResult = Invoke-Pester -Configuration $pesterConfig
    if ($TestResult.Result -ne 'Passed') {
        throw 'Tests failed'
        return $LASTEXITCODE
    }
}
