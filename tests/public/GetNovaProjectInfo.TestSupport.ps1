function Get-NovaCliInstalledVersion {param($Module) return '1.2.3'}
function Format-NovaCliVersionString {param($Name, $Version) return "$Name $Version"}
function Get-NovaProjectInfoContext {param($Path) return [pscustomobject]@{Path=$Path}}
function Get-NovaProjectInfoResult {param($WorkflowContext, [switch]$Version)
    if ($Version) {return '9.9.9'}
    return [pscustomobject]@{Name='X'; Path=$WorkflowContext.Path}
}
