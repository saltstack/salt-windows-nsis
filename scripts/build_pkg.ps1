param(
    [Parameter(Mandatory=$false)]
    [Alias("v")]
    # The version of Salt to be built. If this is not passed, the script will
    # attempt to get it from the git describe command on the Salt source
    # repo
    [String] $Version
)

Write-Host $("=" * 80)
Write-Host "Build NullSoft Installer for Salt"
Write-Host $("-" * 80)

# Script Variables
$OS_ARCH        = (Get-CimInstance Win32_OperatingSystem).OSArchitecture
if ( $OS_ARCH -eq "64-bit" ) {
    $ARCH           = "amd64"
    $NSIS_DIR       = "$( ${env:ProgramFiles(x86)} )\NSIS"
    $SALT_DEP_URL   = "https://repo.saltproject.io/windows/dependencies/64"
} else {
    $ARCH           = "x86"
    $NSIS_DIR       = "${env:ProgramFiles}\NSIS"
    $SALT_DEP_URL   = "https://repo.saltproject.io/windows/dependencies/32"
}

# Python Variables
$PY_VERSION     = "3.8"
$PY_DOT_VERSION = "3.8.13"
$PYTHON_DIR     = "C:\Python$($PY_VERSION -replace "\.")"
$PYTHON_BIN     = "$PYTHON_DIR\python.exe"
$SCRIPTS_DIR    = "$PYTHON_DIR\Scripts"

# Build Variables
$SCRIPT_DIR     = (Get-ChildItem "$($myInvocation.MyCommand.Definition)").DirectoryName
$PROJECT_DIR    = $(git rev-parse --show-toplevel)
$SALT_SRC_DIR   = "$( (Get-Item $PROJECT_DIR).Parent.FullName )\salt"
$BUILD_DIR      = "$SCRIPT_DIR\buildenv"
$BUILD_DIR_BIN  = "$BUILD_DIR\bin"
$BUILD_DIR_SALT = "$BUILD_DIR_BIN\Lib\site-packages\salt"
$BUILD_DIR_CONF = "$BUILD_DIR\configs"
$INSTALLER_DIR  = "$SCRIPT_DIR\installer"
$PREREQ_DIR     = "$SCRIPT_DIR\prereqs"

#-------------------------------------------------------------------------------
# Verify Environment
#-------------------------------------------------------------------------------
Write-Host "Verifying Salt Source Present: " -NoNewline
if ( Test-Path -Path $SALT_SRC_DIR ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit
}

Write-Host "Verifying Python Installation: " -NoNewline
if ( Test-Path -Path "$PYTHON_DIR\python.exe" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "Verifying Salt Installation: " -NoNewline
if ( Test-Path -Path "$SCRIPTS_DIR\salt-minion.exe" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "Verifying NSIS Installation: " -NoNewline
if ( Test-Path -Path "$NSIS_DIR\makensis.exe" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

#-------------------------------------------------------------------------------
# Verify Variables
#-------------------------------------------------------------------------------

if ( [String]::IsNullOrEmpty($Version) ) {
    Write-Host "Getting Salt version from Source: " -NoNewline
    Push-Location $SALT_SRC_DIR
    $Version = $( git describe )
    $Version = $Version.Trim("v")
    Pop-Location
    if ( ! ([String]::IsNullOrEmpty($Version)) ) {
        Write-Host "$Version" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

#-------------------------------------------------------------------------------
# Cleaning Build Environment
#-------------------------------------------------------------------------------
if ( Test-Path -Path $BUILD_DIR_BIN ) {
    Write-Host "Removing Bin Directory: " -NoNewline
    Remove-Item -Path $BUILD_DIR_BIN -Recurse -Force
    if ( ! (Test-Path -Path $BUILD_DIR_BIN) ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

if ( Test-Path -Path $BUILD_DIR_CONF ) {
    Write-Host "Removing Configs Directory: " -NoNewline
    Remove-Item -Path $BUILD_DIR_CONF -Recurse -Force
    if ( ! (Test-Path -Path $BUILD_DIR_CONF) ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

if ( Test-Path -Path $PREREQ_DIR ) {
    Write-Host "Removing PreReq Directory: " -NoNewline
    Remove-Item -Path $PREREQ_DIR -Recurse -Force
    if ( ! (Test-Path -Path $PREREQ_DIR) ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

#-------------------------------------------------------------------------------
# Staging the Build Environment
#-------------------------------------------------------------------------------
Write-Host "Copying $PYTHON_DIR to Bin: " -NoNewline
Copy-Item -Path "$PYTHON_DIR" -Destination "$BUILD_DIR_BIN" -Recurse
if ( Test-Path -Path "$BUILD_DIR_BIN\python.exe" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "Copying config files from Salt: " -NoNewline
New-Item -Path $BUILD_DIR_CONF -ItemType Directory | Out-Null
Copy-Item -Path "$SALT_SRC_DIR\conf\minion" -Destination "$BUILD_DIR_CONF"
if ( Test-Path -Path "$BUILD_DIR_CONF\minion" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

Write-Host "Copying SSM to Bin: " -NoNewline
Invoke-WebRequest -Uri "$SALT_DEP_URL/ssm-2.24-103-gdee49fc.exe" -OutFile "$BUILD_DIR_BIN\ssm.exe"
if ( Test-Path -Path "$BUILD_DIR_BIN\ssm.exe" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

New-Item -Path $PREREQ_DIR -ItemType Directory | Out-Null

# 32-bit binaries are only needed for x86 installer
if ( $OS_ARCH -eq "32-bit" ) {
    Write-Host "Copying VCRedist 2013 x86 to prereqs: " -NoNewline
    Invoke-WebRequest -Uri "$SALT_DEP_URL/vcredist_x86_2013.exe" -OutFile "$PREREQ_DIR\vcredist_x86_2013.exe"
    if ( Test-Path -Path "$PREREQ_DIR\vcredist_x86_2013.exe" ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }

    Write-Host "Copying Universal C Runtimes x86 to prereqs: " -NoNewline
    Invoke-WebRequest -Uri "$SALT_DEP_URL/ucrt_x86.zip" -OutFile "$PREREQ_DIR\ucrt_x86.zip"
    if ( Test-Path -Path "$PREREQ_DIR\ucrt_x86.zip" ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

# 64-bit binaries are only needed for x86 installer
if ( $OS_ARCH -eq "64-bit" ) {
    Write-Host "Copying VCRedist 2013 x64 to prereqs: " -NoNewline
    Invoke-WebRequest -Uri "$SALT_DEP_URL/vcredist_x64_2013.exe" -OutFile "$PREREQ_DIR\vcredist_x64_2013.exe"
    if ( Test-Path -Path "$PREREQ_DIR\vcredist_x64_2013.exe" ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }

    Write-Host "Copying Universal C Runtimes x64 to prereqs: " -NoNewline
    Invoke-WebRequest -Uri "$SALT_DEP_URL/ucrt_x64.zip" -OutFile "$PREREQ_DIR\ucrt_x64.zip"
    if ( Test-Path -Path "$PREREQ_DIR\ucrt_x64.zip" ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

#-------------------------------------------------------------------------------
# Make the Binaries in the Scripts directory portable
#-------------------------------------------------------------------------------
$binaries = Get-ChildItem -Path "$BUILD_DIR_BIN\Scripts" -Filter "*.exe"
$binaries | ForEach-Object {
    Write-Host "Making $_.Name Portable: " -NoNewline
    $before = $_.LastWriteTime
    Start-Process -FilePath "$PYTHON_BIN" `
                  -ArgumentList "$SCRIPT_DIR\portable.py", "-f", "$($_.FullName)" `
                  -Wait -WindowStyle Hidden
    $after = (Get-Item -Path $_.FullName).LastWriteTime
    if ( $after -gt $before) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
    }
}

#-------------------------------------------------------------------------------
# Remove Non-Windows Execution Modules
#-------------------------------------------------------------------------------
Write-Host "Removing Non-Windows Execution Modules: " -NoNewline
$modules = "acme",
           "aix",
           "alternatives",
           "apcups",
           "apf",
           "apt",
           "arista",
           "at",
           "bcache",
           "blockdev",
           "bluez",
           "bridge",
           "bsd",
           "btrfs",
           "ceph",
           "container_resource",
           "cron",
           "csf",
           "daemontools",
           "deb*",
           "devmap",
           "dpkg",
           "ebuild",
           "eix",
           "eselect",
           "ethtool",
           "extfs",
           "firewalld",
           "freebsd",
           "genesis",
           "gentoo",
           "glusterfs",
           "gnomedesktop",
           "groupadd",
           "grub_legacy",
           "guestfs",
           "htpasswd",
           "ilo",
           "img",
           "incron",
           "inspector",
           "ipset",
           "iptables",
           "iwtools",
           "k8s",
           "kapacitor",
           "keyboard",
           "keystone",
           "kmod",
           "layman",
           "linux",
           "localemod",
           "locate",
           "logadm",
           "logrotate",
           "lvs",
           "lxc",
           "mac",
           "makeconf",
           "mdadm",
           "mdata",
           "monit",
           "moosefs",
           "mount",
           "napalm",
           "netbsd",
           "netscaler",
           "neutron",
           "nfs3",
           "nftables",
           "nova",
           "nspawn",
           "openbsd",
           "openstack",
           "openvswitch",
           "opkg",
           "pacman",
           "parallels",
           "parted",
           "pcs",
           "pkgin",
           "pkgng",
           "pkgutil",
           "portage_config",
           "postfix",
           "poudriere",
           "powerpath",
           "pw_",
           "qemu_",
           "quota",
           "redismod",
           "restartcheck",
           "rh_",
           "riak",
           "rpm",
           "runit",
           "s6",
           "scsi",
           "seed",
           "sensors",
           "service",
           "shadow",
           "smartos",
           "smf",
           "snapper",
           "solaris",
           "solr",
           "ssh_",
           "supervisord",
           "sysbench",
           "sysfs",
           "sysrc",
           "system",
           "test_virtual",
           "timezone",
           "trafficserver",
           "tuned",
           "udev",
           "upstart",
           "useradd",
           "uswgi",
           "varnish",
           "vbox",
           "virt",
           "xapi",
           "xbpspkg",
           "xfs",
           "yum*",
           "zfs",
           "znc",
           "zpool",
           "zypper"
$modules | ForEach-Object {
    Remove-Item -Path "$BUILD_DIR_SALT\modules\$_*" -Recurse
    if ( Test-Path -Path "$BUILD_DIR_SALT\modules\$_*" ) {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Failed to remove: $BUILD_DIR_SALT\modules\$_"
        exit 1
    }
}
Write-Host "Success" -ForegroundColor Green

#-------------------------------------------------------------------------------
# Remove Non-Windows State Modules
#-------------------------------------------------------------------------------
Write-Host "Removing Non-Windows Execution Modules: " -NoNewline
$states = "acme",
          "alternatives",
          "apt",
          "at",
          "blockdev",
          "ceph",
          "cron",
          "csf",
          "deb",
          "eselect",
          "ethtool",
          "firewalld",
          "glusterfs",
          "gnome",
          "htpasswd",
          "incron",
          "ipset",
          "iptables",
          "k8s",
          "kapacitor",
          "keyboard",
          "keystone",
          "kmod",
          "layman",
          "linux",
          "lxc",
          "mac",
          "makeconf",
          "mdadm",
          "monit",
          "mount",
          "nftables",
          "pcs",
          "pkgng",
          "portage",
          "powerpath",
          "quota",
          "redismod",
          "smartos",
          "snapper",
          "ssh",
          "supervisord",
          "sysrc",
          "trafficserver",
          "tuned",
          "vbox",
          "virt.py",
          "zfs",
          "zpool"
$states | ForEach-Object {
    Remove-Item -Path "$BUILD_DIR_SALT\states\$_*" -Recurse
    if ( Test-Path -Path "$BUILD_DIR_SALT\states\$_*" ) {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "Failed to remove: $BUILD_DIR_SALT\states\$_"
        exit 1
    }
}
Write-Host "Success" -ForegroundColor Green

Write-Host "Removing unneeded files (.pyc, .chm): " -NoNewline
$remove = "*.pyc",
          "__pycache__",
          "*.chm"
$remove | ForEach-Object {
    $found = Get-ChildItem -Path "$BUILD_DIR_BIN\$_" -Recurse
    $found | ForEach-Object {
        Remove-Item -Path "$_" -Recurse -Force
        if ( Test-Path -Path $_ ) {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "Failed to remove: $_"
            exit 1
        }
    }
}
Write-Host "Success" -ForegroundColor Green

#-------------------------------------------------------------------------------
# Build the Installer
#-------------------------------------------------------------------------------
Write-Host "Building the Installer: " -NoNewline
$installer_name = "Salt-Minion-$Version-Py$($PY_VERSION.Split(".")[0])-$ARCH-Setup.exe"
Start-Process -FilePath $NSIS_DIR\makensis.exe `
              -ArgumentList "/DSaltVersion=$Version", 
                            "$INSTALLER_DIR\Salt-Minion-Setup.nsi" `
              -Wait -WindowStyle Hidden
if ( Test-Path -Path "$INSTALLER_DIR\$installer_name" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}


if ( ! (Test-Path -Path "$PROJECT_DIR\build") ) {
    New-Item -Path "$PROJECT_DIR\build" -ItemType Directory | Out-Null
}
if ( Test-Path -Path "$PROJECT_DIR\build\$installer_name" ) {
    Write-Host "Backing up existing installer: " -NoNewline
    $new_name = "$installer_name.$( Get-Date -UFormat %s ).bak"
    Move-Item -Path "$PROJECT_DIR\build\$installer_name" `
              -Destination "$PROJECT_DIR\build\$new_name"
    if ( Test-Path -Path "$PROJECT_DIR\build\$new_name" ) {
        Write-Host "Success" -ForegroundColor Green
    } else {
        Write-Host "Failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Moving the Installer: " -NoNewline
Move-Item -Path "$INSTALLER_DIR\$installer_name" -Destination "$PROJECT_DIR\build"
if ( Test-Path -Path "$PROJECT_DIR\build\$installer_name" ) {
    Write-Host "Success" -ForegroundColor Green
} else {
    Write-Host "Failed" -ForegroundColor Red
    exit 1
}

#-------------------------------------------------------------------------------
# Finished
#-------------------------------------------------------------------------------
Write-Host $("-" * 80)
Write-Host "Build NullSoft Installer for Salt Completed"
Write-Host $("=" * 80)
Write-Host "Installer can be found in the following directory:"
Write-Host "$PROJECT_DIR\build\$installer_name"
Start $PROJECT_DIR\build