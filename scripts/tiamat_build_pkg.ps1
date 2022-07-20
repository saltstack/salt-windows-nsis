<#
.SYNOPSIS
Script that builds a NullSoft Installer package for Salt based on a Tiamat
build.

.DESCRIPTION
This script creates a NullSoft Installer for Salt based on the artifact created
by salt-pkg or salt-pkg-priv.

.EXAMPLE
tiamat_build_pkg.ps1

#>
# Script Preferences
$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "Stop"

Write-Host "==================================================================="
Write-Host "Salt Windows Build Tiamat Package Script"
Write-Host "==================================================================="

#-------------------------------------------------------------------------------
# Variables
#-------------------------------------------------------------------------------
$script_dir    = dir "$($myInvocation.MyCommand.Definition)"
$script_dir    = $script_dir.DirectoryName
$bin_dir       = "$script_dir\buildenv_tiamat\bin"
$config_dir    = "$script_dir\buildenv_tiamat\configs"
$installer_dir = "$script_dir\installer"
$prereqs_dir   = "$script_dir\prereqs"
$project_dir   = (Get-Item (git rev-parse --show-toplevel)).FullName

#-------------------------------------------------------------------------------
# Validate Environment
#-------------------------------------------------------------------------------
# Validate Project Dir
Write-Host "- Validating Project Directory: " -NoNewLine
if (Test-Path "$((Get-Item $project_dir).parent.FullName)\salt-pkg") {
    $salt_pkg_dir  = "$((Get-Item $project_dir).parent.FullName)\salt-pkg"
    Write-Host "Success" -ForegroundColor Green
} elseif (Test-Path "$((Get-Item $project_dir).parent.FullName)\salt-pkg-priv") {
    $salt_pkg_dir = "$((Get-Item $project_dir).parent.FullName )\salt-pkg-priv"
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Could not find source directory in $((Get-Item $project_dir).parent.FullName)"
    Write-Host "Make sure this repo is cloned next to the salt-pkg repo"
    exit 1
}

# Validate artifacts directory
$artifacts_dir = "$salt_pkg_dir\artifacts"
Write-Host "- Validating Artifacts Directory: " -NoNewLine
if (Test-Path "$artifacts_dir") {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Could not find artifact directory at $artifacts_dir"
    exit 1
}

#-------------------------------------------------------------------------------
# Check PreReqs
#-------------------------------------------------------------------------------
Write-Host "- Checking for NullSoft Compiler: " -NoNewLine
If (Test-Path "${env:ProgramFiles}\NSIS") {
    $nsis_dir = "${env:ProgramFiles}\NSIS"
} Else {
    $nsis_dir = "${env:ProgramFiles(x86)}\NSIS"
}
If (Test-Path "$nsis_dir\makensis.exe") {
    $nsis_bin = "$nsis_dir\makensis.exe"
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

# Make sure bin directory doesn't exist
If (Test-Path "$bin_dir") {
    Write-Host "- Removing bin directory: " -NoNewLIne
    Remove-Item -Path $bin_dir -Force -Recurse
    If (!(Test-Path "$bin_dir")) {
        Write-Host "Success" -ForegroundColor Green
    } Else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

# Make sure salt directory doesn't exist in Temp
If (Test-Path "${env:Temp}\salt") {
    Write-Host "- Removing salt directory in temp: " -NoNewLIne
    Remove-Item -Path "${env:Temp}\salt" -Force -Recurse
    If (!(Test-Path "${env:Temp}\salt")) {
        Write-Host "Success" -ForegroundColor Green
    } Else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

#-------------------------------------------------------------------------------
# Prepare the Artifact
#-------------------------------------------------------------------------------
# Find the zip file in the artifacts directory
Write-Host "- Searching for zipfile in artifacts: " -NoNewLine
$zip_file = Get-ChildItem -Path $artifacts_dir -Include *.zip -Recurse
$zip_dir = Split-Path $zip_file
If ($zip_file) {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

# Get the Version from the Artifact
Write-Host "- Getting version from artifact: " -NoNewLine
$dir_name = Split-Path $zip_dir -Leaf
$version = $dir_name.Split("-")[0]
If ($version) {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

# Unzip the zipfile to temp
Write-Host "- Unzipping zipped artifact: " -NoNewLine
try {
    Expand-Archive $zip_file -DestinationPath $env:Temp
    Write-Host "Success" -ForegroundColor Green
} catch {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

#-------------------------------------------------------------------------------
# Create the build_env
#-------------------------------------------------------------------------------
# Move the extracted directory to bin
Write-Host "- Moving salt folder to bin: " -NoNewLine
Move-Item -Path "${env:Temp}\salt\salt" -Destination $bin_dir
If ($bin_dir) {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

# Move SSM to bin
Write-Host "- Moving ssm.exe to bin: " -NoNewLine
Move-Item -Path "${env:Temp}\salt\ssm.exe" -Destination $bin_dir
If ("$bin_dir\ssm.exe") {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

# Copy master/minion config files from salt project
If (! (Test-Path -Path "$config_dir")) {
    Write-Host "- Creating config directory: " -NoNewline
    New-Item -Path $config_dir -ItemType Directory | Out-Null
    If (Test-Path -Path "$config_dir") {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}
If (Test-Path -Path "$artifacts_dir/master") {
    Write-Host "- Staging master config: " -NoNewline
    Move-Item -Path "$artifacts_dir\master" -Destination "$config_dir"
    if (Test-Path -Path "$config_dir\master") {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}
If (Test-Path -Path "$artifacts_dir/minion") {
    Write-Host "- Staging minion config: " -NoNewline
    Move-Item -Path "$artifacts_dir\minion" -Destination "$config_dir"
    if ( Test-Path -Path "$config_dir\minion" ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

#-------------------------------------------------------------------------------
# Stage the PreReqs
#-------------------------------------------------------------------------------
# Make sure the prereqs dir is empty
If (Test-Path $prereqs_dir) {
    Write-Host "- Cleaning prereqs dir: " -NoNewLine
    Remove-Item -Path "$prereqs_dir" -Force -Recurse | Out-Null
    If (!(Test-Path "$prereqs_dir")) {
        Write-Host "Success" -ForegroundColor Green
    } Else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}
New-Item -Path "$prereqs_dir" -ItemType Directory -Force | Out-Null

# Download Prereqs
$url = "https://repo.saltproject.io/windows/dependencies/64/vcredist_x64_2013.exe"
$name = "vcredist_x64_2013.exe"
Write-Host "- Downloading Visual C Redistributable: " -NoNewLine
Invoke-WebRequest -Uri $url -OutFile "$prereqs_dir\$name" | Out-Null
If (Test-Path "$prereqs_dir\$name") {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

$url = "https://repo.saltproject.io/windows/dependencies/64/ucrt_x64.zip"
$name = "ucrt_x64.zip"
Write-Host "- Downloading Universal C Runtime: " -NoNewLine
Invoke-WebRequest -Uri $url -OutFile "$prereqs_dir\$name" | Out-Null
If (Test-Path "$prereqs_dir\$name") {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

#-------------------------------------------------------------------------------
# Make the Minion Installer
#-------------------------------------------------------------------------------
# Make the Salt Minion Installer
Write-Host "- Building the Salt Minion installer: " -NoNewLine
try {
    & $nsis_bin /DSaltVersion=$version /DTiamat "$installer_dir\Salt-Minion-Setup.nsi" | Out-Null
    Write-Host "Success" -ForegroundColor Green
} catch {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "- Getting new installer name: " -NoNewLine
$installer = (Get-ChildItem -Path $installer_dir -Include *.exe -Recurse).Name
If ($installer) {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "==================================================================="
Write-Host "Salt Windows Build Tiamat Package Script Completed Successfully" -ForegroundColor Green
Write-Host "==================================================================="
