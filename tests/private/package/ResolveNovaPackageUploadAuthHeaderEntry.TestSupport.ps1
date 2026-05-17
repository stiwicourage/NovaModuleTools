function Get-NovaPackageUploadToken {param($AuthSettings, $Token, $TokenEnvironmentVariable) return 'tok'}
function Get-NovaPackageUploadAuthHeaderName {param($AuthSettings) return 'Authorization'}
function Get-NovaPackageUploadAuthHeaderValue {param($AuthSettings, $AuthenticationScheme, $HeaderName, $Token) return "Bearer $Token"}
