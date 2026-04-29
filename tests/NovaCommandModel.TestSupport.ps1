${script:novaCommandModelTestSupportRoot} = $PSScriptRoot

function Initialize-NovaCommandModelTestSupport {
    [CmdletBinding()]
    param()

    foreach ($relativePath in @(
        'NovaCommandModel.TestSupport/Assertions.ps1'
        'NovaCommandModel.TestSupport/CliProjectSupport.ps1'
        'NovaCommandModel.TestSupport/ModuleSupport.ps1'
        'NovaCommandModel.TestSupport/PesterSupport.ps1'
        'NovaCommandModel.TestSupport/TextAndHelp.ps1'
    )) {
        . (Join-Path $script:novaCommandModelTestSupportRoot $relativePath)
    }
}

. Initialize-NovaCommandModelTestSupport
