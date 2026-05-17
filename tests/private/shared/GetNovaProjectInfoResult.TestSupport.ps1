function Get-ProjectPreamble {param($ProjectData); return @('# preamble')}
function Get-NovaResolvedProjectManifestSettings {param($ProjectData); return @{Author='Me'}}
function Get-NovaResolvedProjectPackageSettings {param($ProjectData,$ManifestSettings,$ProjectRoot); return @{Id='Mod'}}
