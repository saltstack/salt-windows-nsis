[![Config Tests](https://github.com/saltstack/salt-windows-nsis/actions/workflows/config-tests.yml/badge.svg?branch=main)](https://github.com/saltstack/salt-windows-nsis/actions/workflows/config-tests.yml)

# salt-windows-nsis
Scripts for building a NullSoft Salt installer for Windows

## Overview
This repository contains PowerShell scripts and NullSoft installer scripts for
building a Salt installer for Windows operating systems.

## Try it out
Clone this repository alongside the Salt repo. So, for example, if you have
cloned the Salt repo to ``C:\build`` then clone this repo in the same location.

Then run the ``build.bat`` file that resides in the ``scripts`` directory. That
script will run all the needed scripts required to install a build environment
and build the installer for the Salt project. The file will be placed in the
``build`` directory on the root of the project.

### Prerequisites

The following prerequisites will be installed by the ``build_env.ps1`` script:

* NullSoft Installer Framework
* NSIS Unzip Plugin
* NSIS EnVar Plugin
* NSIS AccessControl Plugin
* NSIS MoveFileFolder Plugin
* Microsoft Visual Studio 2015 Build Tools
* Python 3.8
* Visual C++ Redistributables

### Build & Run

1. Clone this repository next to the Salt repository
2. Run the ``build.bat`` file in the ``scripts`` directory

## Documentation
This project contains scripts for building and developing on Salt. The important
scripts in the ``scripts`` directory. They are as follows:

- ``build_env.ps1`` : A powershell script that sets up all required dependencies
  to build a Salt installer. Those dependencies are:
  - NullSoft Installer Framework and Plugins
  - Microsoft Visual Studio 2015 Build Tools
  - Python 3.8
  - Visual C++ Redistributables
- ``build_pkg.bat`` : Build the NullSoft installer from the contents of the 
  buildenv directory.
- ``build.bat`` : This script uses the ``build_env.ps1`` script and the
  ``build_pkg.bat`` script to create a NullSoft installer with a single command.
- ``clean_env.bat`` : This script cleans the Python environment on the system.
  It uninstalls Python and removes the Python directory.

Additional scripts:
- ``download_url_file.ps1`` : Used by the ``build_pkg.bat`` script to download
  additional dependencies required by the installer itself.
- ``portable.py`` : Used by the ``build_pkg.bat`` script to make the binaries in
  the package portable. It does this by removing the hard-coded path from the
  binary file.
- ``sign.bat`` : This script is used on a system that has access to the
  EV CodeSigning Certificate to sign the created packages.

Directories:
- ``buildenv`` : This is the shell directory that contains some scripts and
  files that will be packaged into the installer and used by Salt itself. The
  ``build_pkg.bat`` script puts a few things in here from the Salt repo. The
  entire Python directory is placed in the ``bin`` directory.
- ``installer`` : This directory contains the NullSoft installer script as well
  as other files needed by that script, such as the icon, panel, and license
  files.
- ``modules`` : This directory contains some custom powershell modules used by
  the ``build_env.ps1`` script. The only one that needs editing from time to
  time is the ``get-settings.psm1`` script, which is basically an ini file that
  contains settings used by the ``build_env.ps1`` script.

## Contributing
The salt-windows-nsis project team welcomes contributions from the community.
If you wish to contribute code and you have not signed our
[contributor license agreement](https://cla.vmware.com/cla/1/preview) (CLA),
our bot will update the issue when you open a Pull Request. For any questions
about the CLA process, please refer to our [FAQ](https://cla.vmware.com/faq).

## License
This project is licensed Apache 2.0. For more detailed information, refer to
[LICENSE](LICENSE).
