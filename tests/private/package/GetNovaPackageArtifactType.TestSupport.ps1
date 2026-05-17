function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function ConvertTo-NovaPackageType {param($Type)
    switch -Regex ($Type) {'\.zip$' {'Zip'; break} '\.nupkg$' {'NuGet'; break} default {throw "bad: $Type"}}
}
