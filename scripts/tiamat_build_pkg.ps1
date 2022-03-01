[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [Alias("v")]
    [String] $Version
)
# TODO: Add some docs
Write-Host "==================================================================="
Write-Host "Salt Windows Build Tiamat Package Script"
Write-Host "==================================================================="

# Script Preferences
$ErrorActionPreference = "Stop"
$global:ProgressPreference = "SilentlyContinue"

# Defining Variables
Write-Host "- Defining Variables: " -NoNewLine
$script_dir    = dir "$($myInvocation.MyCommand.Definition)"
$script_dir    = $script_dir.DirectoryName
$bin_dir       = "$script_dir\buildenv_tiamat\bin"
$config_dir    = "$script_dir\buildenv_tiamat\configs"
$installer_dir = "$script_dir\installer"
$prereqs_dir   = "$script_dir\prereqs"
$project_dir   = (Get-Item (git rev-parse --show-toplevel)).FullName
$salt_pkg_dir  = "$((Get-Item $project_dir).parent.FullName)\salt-pkg"
$artifacts_dir = "$salt_pkg_dir\artifacts"
Write-Host "Success" -ForegroundColor Green

# Validate Directories
Write-Host "- Validating Source Directory: " -NoNewLine
If (Test-Path $salt_pkg_dir) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    Write-Host "Could not find source directory: $salt_pkg_dir"
    Write-Host "Make sure this repo is cloned next to the salt-pkg repo"
    exit 1
}

# Get Version if not supplied on the CLI
If (!$Version) {
    Write-Host "- Getting version from Git: " -NoNewLine
    $location = Get-Location
    Set-Location $salt_pkg_dir
    $Version = (git describe)
    Set-Location $location
    If ($Version) {
        Write-Host "Success" -ForegroundColor Green
    } Else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

# Check prereqs
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

# Find the zip file in the artifacts directory
Write-Host "- Searching for zipfile in artifacts: " -NoNewLine
$zip_file = Get-ChildItem -Path $artifacts_dir -Include *.zip -Recurse
If ($zip_file) {
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

# TODO: Copy master/minion config files from salt project

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
& "$script_dir\download_url_file.ps1" -url $url -file "$prereqs_dir\$name" *> $null
If (Test-Path "$prereqs_dir\$name") {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

$url = "https://repo.saltproject.io/windows/dependencies/64/ucrt_x64.zip"
$name = "ucrt_x64.zip"
Write-Host "- Downloading Universal C Runtime: " -NoNewLine
& "$script_dir\download_url_file.ps1" -url $url -file "$prereqs_dir\$name" *> $null
If (Test-Path "$prereqs_dir\$name") {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

# Make the Salt Minion Installer
Write-Host "- Building the Salt Minion installer: " -NoNewLine
try {
    & $nsis_bin /DSaltVersion=$Version /DTiamat "$installer_dir\Salt-Minion-Setup.nsi" | Out-Null
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

If (Test-Path "$artifacts_dir\$installer") {
    Write-Host "- Removing existing artifact: " -NoNewLine
    Remove-Item -Path "$artifacts_dir\$installer" -Force
    If (!(Test-Path "$artifacts_dir\$installer")) {
        Write-Host "Success" -ForegroundColor Green
    } Else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

# Move the installer to the artifact directory
Write-Host "- Moving installer to artifacts directory: " -NoNewLine
Move-Item -Path "$installer_dir\$installer" -Destination $artifacts_dir -Force
If (Test-Path "$artifacts_dir\$installer") {
    Write-Host "Success" -ForegroundColor Green
} Else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "==================================================================="
Write-Host "Salt Windows Build Tiamat Package Script Completed Successfully" -ForegroundColor Green
Write-Host "==================================================================="
