function Get-NovaCliHelp {
    $help = @'
usage: nova [--version] [--help] <command> [<args>]

These are common Nova commands used in various situations:

start a new module project
   init       Create a new Nova module scaffold

work with the current project
   info       Show project information
   version    Show the current project name and version from project.json
   build      Build the module into the dist folder
   test       Run Pester tests for the project
   bump       Update the module version in project.json

publish and release
   publish    Build, test, and publish the module locally or to a repository
   release    Run the full release flow (build, test, version bump, rebuild, publish)

global options
   --help     Show this help message
   --version  Show the installed NovaModuleTools module name and version
   -Verbose   Show verbose output for the routed PowerShell command
   -WhatIf    Preview build, test, bump, publish, and release without changing files
   -Confirm   Request confirmation before mutating routed commands; nova bump cancels cleanly on No/No to All/Suspend

Examples:
   nova init
   nova init -Path ~/Work
   nova init -Example
   nova init -Example -Path ~/Work
   nova info
   nova version
   nova build
   nova test
   nova bump -WhatIf
   nova publish -local
   nova publish -repository PSGallery -apikey <key>
   nova bump
   nova release -repository PSGallery -apikey <key>

After installing the module on macOS/Linux, run Install-NovaCli once if you want
the standalone 'nova' command available from zsh/bash.

Use 'nova <command>' to run a command, or call the underlying PowerShell cmdlet directly
when you want a scriptable function interface.

Inside PowerShell, 'nova publish -local' also reloads the published module from the
local install path after a successful publish.

Note: 'nova init' is interactive. Use 'nova init -Path <path>' for an explicit destination,
'nova init -Example' for the packaged example scaffold, and do not use 'nova init -WhatIf'.
'@

    return $help
}