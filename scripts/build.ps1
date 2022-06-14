<#
.SYNOPSIS
Parent script that runs all other scripts required to build Salt

.DESCRIPTION
This script Cleans, Installs Dependencies, Builds Python, Installs Salt,
and builds the NullSoft Installer. It depends on the following Scripts
and are called in this order:

- clean_env.ps1
- install_nsis.ps1
- build_python.ps1
- install_salt.ps1
- build_pkg.ps1

.EXAMPLE
build.ps1

.EXAMPLE
build.ps1 -Version 3005 -PythonVersion 3.8.13

#>

param(
    [Parameter(Mandatory=$false)]
    [Alias("v")]
    # The version of Salt to be built. If this is not passed, the script will
    # attempt to get it from the git describe command on the Salt source
    # repo
    [String] $Version,

    [Parameter(Mandatory=$false)]
    [ValidatePattern("^\d{1,2}.\d{1,2}.\d{1,2}$")]
    [ValidateSet(
        # Until Pythonnet supports newer versions
        #"3.10.5",
        #"3.10.4",
        #"3.10.3",
        #"3.9.13",
        #"3.9.12",
        #"3.9.11",
        "3.8.13",
        "3.8.12",
        "3.8.11",
        "3.8.10"
    )]
    [Alias("p")]
    # The version of Python to be built. Pythonnet only supports up to Python
    # 3.8 for now. Pycurl stopped building wheel files after 7.43.0.5 which
    # supported up to 3.8. So we're pinned to the latest version of Python 3.8.
    # We may have to drop support for pycurl.
    # Default is: 3.8.13
    [String] $PythonVersion = "3.8.13"
)

# Script Preferences
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

#-------------------------------------------------------------------------------
# Import Modules
#-------------------------------------------------------------------------------
$SCRIPT_DIR     = (Get-ChildItem "$($myInvocation.MyCommand.Definition)").DirectoryName
Import-Module $SCRIPT_DIR\Modules\uac-module.psm1

#-------------------------------------------------------------------------------
# Check for Elevated Privileges
#-------------------------------------------------------------------------------
If (!(Get-IsAdministrator)) {
    If (Get-IsUacEnabled) {
        # We are not running "as Administrator" - so relaunch as administrator
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition

        # Specify the current working directory
        $newProcess.WorkingDirectory = "$SCRIPT_DIR"

        # Indicate that the process should be elevated
        $newProcess.Verb = "runas";

        # Start the new process
        [System.Diagnostics.Process]::Start($newProcess);

        # Exit from the current, unelevated, process
        Exit
    } Else {
        Throw "You must be administrator to run this script"
    }
}

Write-Host $("#" * 80)
Write-Host "Build Salt"
Write-Host $("#" * 80)

#-------------------------------------------------------------------------------
# Clean the Environment
#-------------------------------------------------------------------------------
PowerShell.exe -file "$SCRIPT_DIR\clean_env.ps1"
if ( ! $? ) {
    Write-Host "Failed to clean the environment"
    exit 1
}

#-------------------------------------------------------------------------------
# Install NSIS
#-------------------------------------------------------------------------------
powershell -file "$SCRIPT_DIR\install_nsis.ps1"
if ( ! $? ) {
    Write-Host "Failed to install NSIS"
    exit 1
}

#-------------------------------------------------------------------------------
# Build Python
#-------------------------------------------------------------------------------
powershell -file "$SCRIPT_DIR\build_python.ps1" -Version $PythonVersion
if ( ! $? ) {
    Write-Host "Failed to build Python"
    exit 1
}

#-------------------------------------------------------------------------------
# Install Salt
#-------------------------------------------------------------------------------
powershell -file "$SCRIPT_DIR\install_salt.ps1"
if ( ! $? ) {
    Write-Host "Failed to install Salt"
    exit 1
}

#-------------------------------------------------------------------------------
# Build Package
#-------------------------------------------------------------------------------
if ( $Version ) {
    powershell -file "$SCRIPT_DIR\build_pkg.ps1" -Version $Version
} else {
    powershell -file "$SCRIPT_DIR\build_pkg.ps1"
}
if ( ! $? ) {
    Write-Host "Failed to build package"
    exit 1
}

Write-Host $("#" * 80)
Write-Host "Build Salt Completed"
Write-Host $("#" * 80)
