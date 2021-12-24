@echo off
@echo Setup Environment to build test installer
@echo ==========================================================================

for /f "delims=" %%a in ('git rev-parse --show-toplevel') do @set "ProjDir=%%a"

if not exist "%ProjDir%\scripts\prereqs" (
    @echo - Creating prereq directory
    mkdir "%ProjDir%\scripts\prereqs"
    @echo - Creating fake binaries
    echo binary > "%ProjDir%\scripts\prereqs\vcredist_x86_2013.exe"
    echo binary > "%ProjDir%\scripts\prereqs\ucrt_x86.zip"
    echo binary > "%ProjDir%\scripts\prereqs\vcredist_x64_2013.exe"
    echo binary > "%ProjDir%\scripts\prereqs\ucrt_x64.zip"
)

if not exist "%ProjDir%\scripts\buildenv\bin" (
    @echo - Creating bin directory
    mkdir "%ProjDir%\scripts\buildenv\bin"
    @echo - Creating fake binaries
    echo binary > "%ProjDir%\scripts\buildenv\bin\ssm.exe"
    echo binary > "%ProjDir%\scripts\buildenv\bin\python.exe"
)

if not exist "%ProjDir%\scripts\buildenv\configs" (
    @echo - Creating conf directory
    mkdir "%ProjDir%\scripts\buildenv\configs"
)

@echo - Copying test minion config
xcopy /Q /Y "%ProjDir%\tests\_files\minion" "%ProjDir%\scripts\buildenv\configs\"

@echo Build fake salt installer using NSIS
@echo ==========================================================================
makensis.exe /DSaltVersion=test /DPythonVersion=3 "%ProjDir%\scripts\installer\Salt-Minion-Setup.nsi"
move "%ProjDir%\scripts\installer\Salt-Minion-test-Py3-AMD64-Setup.exe" "%ProjDir%"

:end
