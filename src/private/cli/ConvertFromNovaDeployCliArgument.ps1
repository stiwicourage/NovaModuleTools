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
            '^(--repository|-Repository)$' {
                $options.Repository = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--repository'
            }
            '^(--url|-Url)$' {
                $options.Url = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--url'
            }
            '^(--path|-Path|-PackagePath)$' {
                Add-NovaCliOptionValue -Options $options -Name 'PackagePath' -Value (Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--path')
            }
            '^(--type|-Type|-PackageType)$' {
                Add-NovaCliOptionValue -Options $options -Name 'PackageType' -Value (Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--type')
            }
            '^(--uploadpath|-UploadPath)$' {
                $options.UploadPath = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--uploadpath'
            }
            '^(--token|-Token)$' {
                $options.Token = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--token'
            }
            '^(--tokenenv|-TokenEnvironmentVariable)$' {
                $options.TokenEnvironmentVariable = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--tokenenv'
            }
            '^(--authscheme|-AuthenticationScheme)$' {
                $options.AuthenticationScheme = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--authscheme'
            }
            '^(--header|-Header)$' {
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


