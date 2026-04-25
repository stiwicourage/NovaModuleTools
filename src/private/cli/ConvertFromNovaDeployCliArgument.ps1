function ConvertFrom-NovaDeployCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}
    $index = 0

    while ($index -lt $Arguments.Count) {
        $token = $Arguments[$index]

        switch -Regex ($token) {
            '^(--repository|-r)$' {
                $options.Repository = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--repository'
            }
            '^(--url|-u)$' {
                $options.Url = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--url'
            }
            '^(--path|-p)$' {
                Add-NovaCliOptionValue -Options $options -Name 'PackagePath' -Value (Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--path')
            }
            '^(--type|-t)$' {
                Add-NovaCliOptionValue -Options $options -Name 'PackageType' -Value (Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--type')
            }
            '^(--upload-path|-o)$' {
                $options.UploadPath = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--upload-path'
            }
            '^(--token|-k)$' {
                $options.Token = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--token'
            }
            '^(--token-env|-e)$' {
                $options.TokenEnvironmentVariable = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--token-env'
            }
            '^(--auth-scheme|-a)$' {
                $options.AuthenticationScheme = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--auth-scheme'
            }
            '^(--header|-H)$' {
                Add-NovaCliHeaderOption -Options $options -HeaderArgument (Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--header')
            }
            default {
                Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
            }
        }

        $index++
    }

    return $options
}


