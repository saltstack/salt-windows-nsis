@echo off
@echo Salt Windows Build Script, which calls the other scripts.
@echo ----------------------------------------------------------------------
@echo.
:: This script builds salt on any machine. It uses the following scripts:
:: - build_env.ps1: Sets up a Python environment will all dependencies Salt will
::                  will require
:: - build_pkg.bat: Bundles the contents of the Python directory into a
::                  nullsoft installer binary

:: The script first calls the `build_env.ps1` script to set up a python
:: environment. Then it installs Salt into that python environment using Salt's
:: `setup.py install` command. Finally, it runs the `build_pkg.bat` to create
:: a NullSoft installer in the `installer` directory (pkg\windows\installer)

:: This script accepts two parameters.
::   Version: The version of Salt being built. If not passed, the version will
::            be determined using `git describe`. The leading `v` will be
::            removed
::   Python: The version of Python to build Salt on (Default is 3). We'll keep
::           this parameter in case Python decides to release version 4

:: These parameters can be passed positionally or as named parameters. Named
:: parameters must be wrapped in quotes.

:: Examples:
::   # To build Salt 3000.3 on Python 3
::   build.bat 3000.3
::   build.bat 3000.3 3

::   # Using named parameters
::   build.bat "Version=3000.3"
::   build.bat "Version=3000.3" "Python=3"

::  # Using a mix
::   build.bat 3000.3 "Python=3"

:: To activate caching, set environment variables
::   SALTREPO_LOCAL_CACHE  for resources from saltstack.com/...
::   SALT_REQ_LOCAL_CACHE  for pip resources specified in req.txt
::   SALT_PIP_LOCAL_CACHE  for pip resources specified in req_pip.txt

:: Make sure the script is run as Admin
@echo Administrative permissions required. Detecting permissions...
@echo ----------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel%==0 (
    echo ...Success: Administrative permissions confirmed.
) else (
    echo ...Failure: This script must be run as Administrator
    goto eof
)
@echo ======================================================================
@echo.

@echo Git required. Detecting git...
@echo ----------------------------------------------------------------------
where git >nul 2>&1
if %errorLevel%==0 (
    echo ...Success: Git found.
) else (
    echo ...Failure: This script needs to call git
    goto eof
)
@echo ======================================================================
@echo.

:: Get Passed Parameters
@echo %~nx0 :: Get Passed Parameters...
@echo ----------------------------------------------------------------------

set "Version="
set "Python="
:: First Parameter
if not "%~1"=="" (
    @echo.%1 | FIND /I "=" > nul && (
        :: Named Parameter
        echo Named Parameter
        set "%~1"
    ) || (
        :: Positional Parameter
        echo Positional Parameter
        set "Version=%~1"
    )
)

:: Second Parameter
if not "%~2"=="" (
    @echo.%2 | FIND /I "=" > nul && (
        :: Named Parameter
        set "%~2"
    ) || (
        :: Positional Parameter
        set "Python=%~2"
    )
)

:: If Python not defined, Assume Python 3
if "%Python%"=="" (
    set Python=3
)

:: Verify valid Python value (3)
:: We may need to add Python 4 in the future (delims=34)
set "x="
for /f "delims=3" %%i in ("%Python%") do set x=%%i
if Defined x (
    echo Invalid Python Version specified. Must be 3. Passed %Python%
    goto eof
)

@echo ======================================================================
@echo.

:: Define Variables
@echo %~nx0 :: Defining Variables...
@echo ----------------------------------------------------------------------
if "%PyDir%"=="" (Set "PyDir=C:\Python38")
if "%PyVerMajor%"=="" (Set "PyVerMajor=3")
if "%PyDirMinor%"=="" (Set "PyVerMinor=8")
Set "PATH=%PATH%;%PyDir%;%PyDir%\Scripts"

Set "CurDir=%~dp0"
for /f "delims=" %%a in ('git rev-parse --show-toplevel') do @set "SrcDir=%%a"

:: The Target Dir is where we will put the installer
Set "TgtDir=%SrcDir%\build"

:: We need to make sure we can find the Source Directory
:trim_directory
    If NOT Exist "%SrcDir%\salt" (
        For %%A in ("%SrcDir%") do (
            if "%%~dpA"=="%SrcDir%" (
                echo "Could not find Source Directory salt"
                echo "Make sure the repo is cloned next to a salt repo"
                exit
            )
            @set "SrcDir=%%~dpA"
        )
        goto :trim_directory
    )

@set "SrcDir=%SrcDir%salt"
@echo Found SrcDir: %SrcDir%
@echo.

:: If Version not defined, Get the version from Git
if "%Version%"=="" (

    @echo "%~nx0 :: Getting version from git"
    @echo ----------------------------------------------------------------------

    :: Change CWD to Source Directory
    pushd %SrcDir%

    :: Get the Version from Git
    for /f %%A in ('git describe') do @set "GitVersion=%%A"

    rem We have to comment with rem here for some reason
    rem Trim the leading "v" character
    @set "Version=%GitVersion:~1%"

    :: Change back to Original CWD
    popd

)

@echo "Found Version: %Version%"
@echo.

@echo ======================================================================
@echo.

:: Create Build Environment
@echo %~nx0 :: Create the Build Environment...
@echo ----------------------------------------------------------------------
PowerShell.exe -ExecutionPolicy RemoteSigned -File "%CurDir%build_env.ps1" -Silent

if not %errorLevel%==0 (
    echo "%CurDir%build_env.ps1" returned errorlevel %errorLevel%. Aborting %~nx0
    goto eof
)
@echo.

:: Remove build and dist directories
@echo %~nx0 :: Remove build and dist directories...
@echo ----------------------------------------------------------------------
"%PyDir%\python.exe" "%SrcDir%\setup.py" clean --all
if not %errorLevel%==0 (
    goto eof
)
If Exist "%SrcDir%\dist" (
    @echo removing %SrcDir%\dist
    rd /S /Q "%SrcDir%\dist"
)
@echo.

:: Install Current Version of salt
@echo %~nx0 :: Install Current Version of salt...
@echo ----------------------------------------------------------------------
"%PyDir%\python.exe" "%SrcDir%\setup.py" --quiet install --force
if not %errorLevel%==0 (
    goto eof
)
@echo.

:: Build the Salt Package
@echo %~nx0 :: Build the Salt Package...
@echo ----------------------------------------------------------------------
call "%CurDir%build_pkg.bat" "%Version%" "%Python%"
@echo.

:: Move the Installer to the build directory
@echo %~nx0 :: Move the Salt Package to the build directory...
@echo ----------------------------------------------------------------------
@set "FileName=Salt-Minion-%Version%-Py%Python%-%Arch%-Setup.exe"
If NOT Exist "%TgtDir%\" (
    @echo - Making TgtDir: %TgtDir%
    mkdir "%TgtDir%"
)
If Exist "%TgtDir%\%FileName%" (
    @echo - Removing existing pkg: %TgtDir%\%FileName%
    del /q "%TgtDir%\%FileName%"
)
@echo - Moving package
@echo - Source: %InsDir%\%FileName%
@echo - Target: %TgtDir%
move /Y "%InsDir%\%FileName%" "%TgtDir%\"
If Exist "%TgtDir%\%FileName%" ( @echo - File moved successfully )

:eof
@echo.
@echo ======================================================================
@echo End of %~nx0
@echo ======================================================================
@echo.
@echo Installation file can be found in the following directory:
@echo %TgtDir%
