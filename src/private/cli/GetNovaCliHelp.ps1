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

Examples:
   nova init ~/Work
   nova info
   nova version
   nova build
   nova test
   nova publish -local
   nova publish -repository PSGallery -apikey <key>
   nova bump
   nova release -repository PSGallery -apikey <key>

After installing the module on macOS/Linux, run Install-NovaCli once if you want
the standalone 'nova' command available from zsh/bash.

Use 'nova <command>' to run a command, or call the underlying PowerShell cmdlet directly
when you want a scriptable function interface.
'@

    return $help
}