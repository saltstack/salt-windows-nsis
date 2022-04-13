#===============================================================================
# You may need to change the execution policy in order to run this script
# Run the following in powershell:
#
# Set-ExecutionPolicy RemoteSigned
#
#===============================================================================
#
#          FILE: tiamat_build_env.ps1
#
#   DESCRIPTION: Tiamat Build Environment Installation for Windows
#
#     COPYRIGHT: (c) 2022 by the SaltStack Team
#
#       LICENSE: Apache 2.0
#  ORGANIZATION: SaltProject (saltproject.io)
#       CREATED: 02/25/2022
#===============================================================================

# Load parameters
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [Alias("S")]
    [switch]$Silent
)

#===============================================================================
# Set global variables
#===============================================================================
$ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"

#===============================================================================
# Get the Directory of actual script
#===============================================================================
$script_path = Get-ChildItem "$($myInvocation.MyCommand.Definition)"
$script_path = $script_path.DirectoryName

#===============================================================================
# Get the name of actual script
#===============================================================================
$script_name = $MyInvocation.MyCommand.Name

Write-Host "==================================================================="
Write-Host ""
Write-Host "               Tiamat Build Environment Installation"
Write-Host ""
Write-Host "               - Installs All NSIS Dependencies"
Write-Host ""
Write-Host "               To run silently add -Silent"
Write-Host "               eg: ${script_name} -Silent"
Write-Host ""
Write-Host "==================================================================="
Write-Host ""

#===============================================================================
# Import Modules
#===============================================================================
Import-Module $script_path\Modules\download-module.psm1
Import-Module $script_path\Modules\get-settings.psm1
Import-Module $script_path\Modules\uac-module.psm1
Import-Module $script_path\Modules\zip-module.psm1
Import-Module $script_path\Modules\start-process-and-test-exitcode.psm1
#===============================================================================
# Check for Elevated Privileges
#===============================================================================
If (!(Get-IsAdministrator)) {
    If (Get-IsUacEnabled) {
        # We are not running "as Administrator" - so relaunch as administrator
        # Create a new process object that starts PowerShell
        $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

        # Specify the current script path and name as a parameter
        $newProcess.Arguments = $myInvocation.MyCommand.Definition

        # Specify the current working directory
        $newProcess.WorkingDirectory = "$script_path"

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

#-------------------------------------------------------------------------------
# Load Settings
#-------------------------------------------------------------------------------
$ini = Get-Settings

#-------------------------------------------------------------------------------
# Create Directories
#-------------------------------------------------------------------------------
New-Item $ini['Settings']['DownloadDir'] -ItemType Directory -Force | Out-Null
New-Item "$($ini['Settings']['DownloadDir'])\64" -ItemType Directory -Force | Out-Null
New-Item $ini['Settings']['SaltDir'] -ItemType Directory -Force | Out-Null

#-------------------------------------------------------------------------------
# Use 64-bit variables
#-------------------------------------------------------------------------------

$bitPaths    = "64bitPaths"

#-------------------------------------------------------------------------------
# Check for installation of NSIS
#-------------------------------------------------------------------------------
Write-Host " - Checking for NSIS installation: " -NoNewLine
If (Test-Path "$($ini[$bitPaths]['NSISDir'])\NSIS.exe") {
    # Found NSIS, do nothing
    Write-Host "Success" -ForegroundColor Green
} Else {
    # NSIS not found, install
    Write-Host "Missing" -ForegroundColor Yellow
    $file = "$($ini['Prerequisites']['NSIS'])"
    $url  = "$($ini['Settings']['SaltRepo'])/$file"
    $file = "$($ini['Settings']['DownloadDir'])\$file"
    Write-Host " - Downloading: " -NoNewLine
    try {
        DownloadFileWithProgress $url $file *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Install NSIS
    Write-Host " - Installing: " -NoNewLine
    $file = "$($ini['Settings']['DownloadDir'])\$($ini['Prerequisites']['NSIS'])"
    try {
        Start-Process $file -ArgumentList '/S' -Wait -NoNewWindow -PassThru | Out-Null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}

#-------------------------------------------------------------------------------
# Check for installation of NSIS NxS Unzip Plug-in
#-------------------------------------------------------------------------------
Write-Host " - Checking for NSIS NxS Unzip (ansi) Plug-in installation: "  -NoNewLine
If (Test-Path "$( $ini[$bitPaths]['NSISPluginsDirA'] )\nsisunz.dll") {
    # Found NSIS NxS Unzip Plug-in, do nothing
    Write-Host "Success" -ForegroundColor Green
} Else {
    # NSIS NxS Unzip Plug-in (ansi) not found, install
    Write-Host "Missing" -ForegroundColor Yellow
    $file = "$( $ini['Prerequisites']['NSISPluginUnzipA'] )"
    $url  = "$( $ini['Settings']['SaltRepo'] )/$file"
    $file = "$( $ini['Settings']['DownloadDir'] )\$file"
    Write-Host " - Downloading: " -NoNewLine
    try {
        DownloadFileWithProgress $url $file *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Extract Ansi Zip file
    Write-Host " - Extracting: " -NoNewLine
    try {
        Expand-ZipFile $file $ini['Settings']['DownloadDir'] *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Copy dll to plugins directory
    Write-Host " - Installing: " -NoNewLine
    try {
        Move-Item "$( $ini['Settings']['DownloadDir'] )\nsisunz\Release\nsisunz.dll" "$( $ini[$bitPaths]['NSISPluginsDirA'] )\nsisunz.dll" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Remove temp files
    Write-Host " - Cleaning: " -NoNewLine
    try {
        Remove-Item "$( $ini['Settings']['DownloadDir'] )\nsisunz" -Force -Recurse
        Remove-Item "$file" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}

Write-Host " - Checking for NSIS NxS Unzip (unicode) Plug-in installation: " -NoNewLine
If (Test-Path "$( $ini[$bitPaths]['NSISPluginsDirU'] )\nsisunz.dll") {
    # Found NSIS NxS Unzip Plug-in (unicode), do nothing
    Write-Host "Success" -ForegroundColor Green
} Else {
    # Unicode Plugin
    Write-Host "Missing" -ForegroundColor Yellow
    $file = "$( $ini['Prerequisites']['NSISPluginUnzipU'] )"
    $url  = "$( $ini['Settings']['SaltRepo'] )/$file"
    $file = "$( $ini['Settings']['DownloadDir'] )\$file"
    Write-Host " - Downloading: " -NoNewLine
    try {
        DownloadFileWithProgress $url $file *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Extract Unicode Zip file
    Write-Host " - Extracting: " -NoNewLine
    try {
        Expand-ZipFile $file $ini['Settings']['DownloadDir'] *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Copy dll to plugins directory
    Write-Host " - Installing: " -NoNewLine
    try {
        Move-Item "$( $ini['Settings']['DownloadDir'] )\NSISunzU\Plugin unicode\nsisunz.dll" "$( $ini[$bitPaths]['NSISPluginsDirU'] )\nsisunz.dll" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Remove temp files
    Write-Host " - Cleaning: " -NoNewLine
    try {
        Remove-Item "$( $ini['Settings']['DownloadDir'] )\NSISunzU" -Force -Recurse
        Remove-Item "$file" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}

#-------------------------------------------------------------------------------
# Check for installation of EnVar Plugin for NSIS
#-------------------------------------------------------------------------------
Write-Host " - Checking for EnVar Plugin of NSIS installation: " -NoNewLine
If ( (Test-Path "$($ini[$bitPaths]['NSISPluginsDirA'])\EnVar.dll") -and (Test-Path "$($ini[$bitPaths]['NSISPluginsDirU'])\EnVar.dll") ) {
    # Found EnVar Plugin for NSIS, do nothing
    Write-Host "Success" -ForegroundColor Green
} Else {
    # EnVar Plugin for NSIS not found, install
    Write-Host "Missing" -ForegroundColor Yellow
    $file = "$($ini['Prerequisites']['NSISPluginEnVar'])"
    $url  = "$($ini['Settings']['SaltRepo'])/$file"
    $file = "$($ini['Settings']['DownloadDir'])\$file"
    Write-Host " - Downloading: " -NoNewLine
    try {
        DownloadFileWithProgress $url $file *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Extract Zip File
    Write-Host " - Extracting: " -NoNewLine
    try {
        Expand-ZipFile $file "$($ini['Settings']['DownloadDir'])\nsisenvar" *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Copy dlls to plugins directory (both ANSI and Unicode)
    Write-Host " - Installing: " -NoNewLine
    try {
        Move-Item "$( $ini['Settings']['DownloadDir'] )\nsisenvar\Plugins\x86-ansi\EnVar.dll" "$( $ini[$bitPaths]['NSISPluginsDirA'] )\EnVar.dll" -Force
        Move-Item "$( $ini['Settings']['DownloadDir'] )\nsisenvar\Plugins\x86-unicode\EnVar.dll" "$( $ini[$bitPaths]['NSISPluginsDirU'] )\EnVar.dll" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Remove temp files
    Write-Host " - Cleaning: " -NoNewLine
    try {
        Remove-Item "$( $ini['Settings']['DownloadDir'] )\nsisenvar" -Force -Recurse
        Remove-Item "$file" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}

#-------------------------------------------------------------------------------
# Check for installation of AccessControl Plugin for NSIS
#-------------------------------------------------------------------------------
Write-Host " - Checking for AccessControl Plugin installation: " -NoNewLine
If ( (Test-Path "$($ini[$bitPaths]['NSISPluginsDirA'])\AccessControl.dll") -and (Test-Path "$($ini[$bitPaths]['NSISPluginsDirU'])\AccessControl.dll") ) {
    # Found AccessControl Plugin, do nothing
    Write-Host "Success" -ForegroundColor Green
} Else {
    # AccessControl Plugin not found, install
    Write-Host "Missing" -ForegroundColor Yellow
    $file = "$($ini['Prerequisites']['NSISPluginAccessControl'])"
    $url  = "$($ini['Settings']['SaltRepo'])/$file"
    $file = "$($ini['Settings']['DownloadDir'])\$file"
    Write-Host " - Downloading: " -NoNewLine
    try {
        DownloadFileWithProgress $url $file *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Extract Zip File
    Write-Host " - Extracting: " -NoNewLine
    try {
        Expand-ZipFile $file "$($ini['Settings']['DownloadDir'])\nsisaccesscontrol" *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Copy dlls to plugins directory (both ANSI and Unicode)
    Write-Host " - Installing: " -NoNewLine
    try {
        Move-Item "$( $ini['Settings']['DownloadDir'] )\nsisaccesscontrol\Plugins\i386-ansi\AccessControl.dll" "$( $ini[$bitPaths]['NSISPluginsDirA'] )\AccessControl.dll" -Force
        Move-Item "$( $ini['Settings']['DownloadDir'] )\nsisaccesscontrol\Plugins\i386-unicode\AccessControl.dll" "$( $ini[$bitPaths]['NSISPluginsDirU'] )\AccessControl.dll" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Remove temp files
    Write-Host " - Cleaning: " -NoNewLine
    try {
        Remove-Item "$( $ini['Settings']['DownloadDir'] )\nsisaccesscontrol" -Force -Recurse
        Remove-Item "$file" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}

#-------------------------------------------------------------------------------
# Check for installation of the MoveFileFolder Library for NSIS
#-------------------------------------------------------------------------------
Write-Host " - Checking for MoveFileFolder Library installation: " -NoNewLine
If ( Test-Path "$($ini[$bitPaths]['NSISDir'])\Include\MoveFileFolder.nsh" ) {
    # Found MoveFileFolder Library for NSIS, do nothing
    Write-Host "Success" -ForegroundColor Green
} Else {
    # MoveFileFolder Library for NSIS not found, install
    Write-Host "Missing" -ForegroundColor Yellow
    $file = "$($ini['Prerequisites']['NSISLibMoveFileFolder'])"
    $url  = "$($ini['Settings']['SaltRepo'])/$file"
    $file = "$($ini['Settings']['DownloadDir'])\$file"
    Write-Host " - Downloading: " -NoNewLine
    try {
        DownloadFileWithProgress $url $file *> $null
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }

    # Move libary to the include directory
    Write-Host " - Installing: " -NoNewLine
    try {
        Move-Item "$file" "$( $ini[$bitPaths]['NSISDir'] )\Include\MoveFileFolder.nsh" -Force
        Write-Host "Success" -ForegroundColor Green
    } catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host $_
    }
}

#-------------------------------------------------------------------------------
# Script complete
#-------------------------------------------------------------------------------
Write-Host "==================================================================="
Write-Host " $script_name :: Tiamat Build Environment Script Complete"
Write-Host "==================================================================="
Write-Host ""

If (-Not $Silent) {
    Write-Host "Press any key to continue ..."
    $HOST.UI.RawUI.Flushinputbuffer() | Out-Null
    $HOST.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
}

#-------------------------------------------------------------------------------
# Remove the temporary download directory
#-------------------------------------------------------------------------------
Write-Host " ------------------------------------------------------------------"
Write-Host " - $script_name :: Cleaning up downloaded files"
Write-Host " ------------------------------------------------------------------"
Write-Host ""
Remove-Item $($ini['Settings']['DownloadDir']) -Force -Recurse
