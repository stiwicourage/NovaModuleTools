BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleUpdateNotificationSafely.ps1')

    function Invoke-NovaModuleUpdateNotification {param([int]$TimeoutMilliseconds)}
}

Describe 'Invoke-NovaModuleUpdateNotificationSafely' {
    It 'swallows update lookup failures' {
        Mock Invoke-NovaModuleUpdateNotification {throw 'network issue'}

        {Invoke-NovaModuleUpdateNotificationSafely} | Should -Not -Throw
        Assert-MockCalled Invoke-NovaModuleUpdateNotification -Times 1
    }
}
