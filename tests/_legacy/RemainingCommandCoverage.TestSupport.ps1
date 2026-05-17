function Get-TestNovaPesterConfig {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
    Run = [pscustomobject]@{
    Path = $null
    PassThru = $false
    Exit = $false
    Throw = $false
    }
    Filter = [pscustomobject]@{
    Tag = @()
    ExcludeTag = @()
    }
    Output = [pscustomobject]@{
    Verbosity = 'Detailed'
    RenderMode = 'Auto'
    }
    TestResult = [pscustomobject]@{
    OutputPath = $null
    }
    }
}

function Get-TestNovaTestWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Config,
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][scriptblock]$ArtifactWriter,
        [Parameter(Mandatory)][scriptblock]$ReportWriter
    )

    return [pscustomobject]@{
        TestResultDirectory = [System.IO.Path]::Join($ProjectRoot, 'artifacts')
        TestResultPath = [System.IO.Path]::Join($ProjectRoot, 'artifacts', 'TestResults.xml')
        PesterConfig = $Config
        TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = $ArtifactWriter}
        TestResultReportWriter = [pscustomobject]@{ScriptBlock = $ReportWriter}
    }
}

function Get-TestNovaPesterWorkflowReportContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Config,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $expectedOutputPath = [System.IO.Path]::Join($ProjectRoot, 'artifacts', 'TestResults.xml')
    $artifactWriter = Get-TestNovaPesterArtifactWriter
    $reportWriter = Get-TestNovaPesterReportWriter -ExpectedOutputPath $expectedOutputPath

    return Get-TestNovaTestWorkflowContext -Config $Config -ProjectRoot $ProjectRoot -ArtifactWriter $artifactWriter -ReportWriter $reportWriter
}

function Get-TestNovaPesterArtifactWriter {
    [CmdletBinding()]
    param()

    return {
        param($TestResult, $OutputPath, $ReportWriter)

        & $ReportWriter -TestResult $TestResult -OutputPath $OutputPath
    }
}

function Get-TestNovaPesterReportWriter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ExpectedOutputPath
    )

    return {
        param($TestResult, $OutputPath)

        $global:reportWasWritten = $null -ne $TestResult -and $OutputPath -eq $ExpectedOutputPath
    }.GetNewClosure()
}
