echo off
echo ======================================================================
echo Salt Windows Clean Script
echo .
echo - Uninstalls Python and removes the Python directory
echo ======================================================================
echo.

:: Make sure the script is run as Admin
echo Administrative permissions required. Detecting permissions ...
echo ----------------------------------------------------------------------
net session >nul 2>&1
if %errorLevel%==0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Failure: This script must be run as Administrator
    goto eof
)
echo.

:CheckPython27
if not exist "\Python27" goto CheckPython35

:RemovePython27
    :: Uninstall Python 2.7
    echo %0 :: Uninstalling Python 2 ...
    echo -----------------------------------------------------------------------
    echo %0 :: - 2.7.12 (32 bit)
    MsiExec.exe /X {9DA28CE5-0AA5-429E-86D8-686ED898C665} /QN
    echo %0 :: - 2.7.12 (64 bit)
    MsiExec.exe /X {9DA28CE5-0AA5-429E-86D8-686ED898C666} /QN
    echo %0 :: - 2.7.13 (32 bit)
    MsiExec.exe /X {4A656C6C-D24A-473F-9747-3A8D00907A03} /QN
    echo %0 :: - 2.7.13 (64 bit)
    MsiExec.exe /X {4A656C6C-D24A-473F-9747-3A8D00907A04} /QN
    echo %0 :: - 2.7.14 (32 bit)
    MsiExec.exe /X {0398A685-FD8D-46B3-9816-C47319B0CF5E} /QN
    echo %0 :: - 2.7.14 (64 bit)
    MsiExec.exe /X {0398A685-FD8D-46B3-9816-C47319B0CF5F} /QN
    echo %0 :: - 2.7.15 (32 bit)
    MsiExec.exe /X {16CD92A4-0152-4CB7-8FD6-9788D3363616} /QN
    echo %0 :: - 2.7.15 (64 bit)
    MsiExec.exe /X {16CD92A4-0152-4CB7-8FD6-9788D3363617} /QN

    echo.

    :: Wipe the Python directory
    echo %0 :: Removing the C:\Python27 Directory ...
    echo -----------------------------------------------------------------------
    if exist "C:\Python27" rd /s /q "C:\Python27"
    if %errorLevel%==0 (
        echo Successful
    ) else (
        echo Failed, please remove manually
    )

:CheckPython35
if not exist "\Python35" goto CheckPython37

:RemovePython35
    echo %0 :: Uninstalling Python 3 ...
    echo -----------------------------------------------------------------------
    :: 64 bit
    if exist "%LOCALAPPDATA%\Package Cache\{b94f45d6-8461-440c-aa4d-bf197b2c2499}" (
        echo %0 :: - 3.5.3 64bit
        "%LOCALAPPDATA%\Package Cache\{b94f45d6-8461-440c-aa4d-bf197b2c2499}\python-3.5.3-amd64.exe" /uninstall /quiet
    )
    if exist "%LOCALAPPDATA%\Package Cache\{5d57524f-af24-49a7-b90b-92138880481e}" (
        echo %0 :: - 3.5.4 64bit
        "%LOCALAPPDATA%\Package Cache\{5d57524f-af24-49a7-b90b-92138880481e}\python-3.5.4-amd64.exe" /uninstall /quiet
    )

    :: 32 bit
    if exist "%LOCALAPPDATA%\Package Cache\{a10037e1-4247-47c9-935b-c5ca049d0299}" (
        echo %0 :: - 3.5.3 32bit
        "%LOCALAPPDATA%\Package Cache\{a10037e1-4247-47c9-935b-c5ca049d0299}\python-3.5.3" /uninstall /quiet
    )
    if exist "%LOCALAPPDATA%\Package Cache\{06e841fa-ca3b-4886-a820-cd32c614b0c1}" (
        echo %0 :: - 3.5.4 32bit
        "%LOCALAPPDATA%\Package Cache\{06e841fa-ca3b-4886-a820-cd32c614b0c1}\python-3.5.4" /uninstall /quiet
    )

    :: wipe the Python directory
    echo %0 :: Removing the C:\Python35 Directory ...
    echo -----------------------------------------------------------------------
    if exist "C:\Python35" rd /s /q "C:\Python35"
    if %errorLevel%==0 (
        echo Successful
    ) else (
        echo Failed, please remove manually
    )

:CheckPython37
if not exist "\Python37" goto CheckPython38

:RemovePython37
    echo %0 :: Uninstalling Python 3.7 ...
    echo -----------------------------------------------------------------------
    :: 64 bit
    if exist "%LOCALAPPDATA%\Package Cache\{8ae589dd-de2e-42cd-af56-102374115fee}" (
        echo %0 :: - 3.7.4 64bit
        "%LOCALAPPDATA%\Package Cache\{8ae589dd-de2e-42cd-af56-102374115fee}\python-3.7.4-amd64.exe" /uninstall /quiet
    )

    :: 32 bit
    if exist "%LOCALAPPDATA%\Package Cache\{b66087e3-469e-4725-8b9b-f0981244afea}" (
        echo %0 :: - 3.7.4 32bit
        "%LOCALAPPDATA%\Package Cache\{b66087e3-469e-4725-8b9b-f0981244afea}\python-3.7.4" /uninstall /quiet
    )
    :: Python Launcher, seems to be the same for 32 and 64 bit
    echo %0 :: - Python Launcher
    msiexec.exe /x {D722DA3A-92F5-454A-BD5D-A48C94D82300} /quiet /qn

    :: wipe the Python directory
    echo %0 :: Removing the C:\Python37 Directory ...
    echo -----------------------------------------------------------------------
    if exist "C:\Python37" rd /s /q "C:\Python37"
    if %errorLevel%==0 (
        echo Successful
    ) else (
        echo Failed, please remove manually
    )

:CheckPython38
if not exist "\Python38" goto CheckPython39

:RemovePython38
    echo %0 :: Uninstalling Python 3.8 ...
    echo -----------------------------------------------------------------------
    :: 64 bit
    if exist "%LOCALAPPDATA%\Package Cache\{ef6306ce-2a12-4d59-887e-ebf00b9e4ab5}" (
        echo %0 :: - 3.8.8 64bit
        "%LOCALAPPDATA%\Package Cache\{ef6306ce-2a12-4d59-887e-ebf00b9e4ab5}\python-3.8.8-amd64.exe" /uninstall /quiet
    )

    :: 32 bit
    if exist "%LOCALAPPDATA%\Package Cache\{ac93da86-1536-4b03-aea1-dc354b5e9282}" (
        echo %0 :: - 3.8.8 32bit
        "%LOCALAPPDATA%\Package Cache\{ac93da86-1536-4b03-aea1-dc354b5e9282}\python-3.8.8" /uninstall /quiet
    )
    :: Python Launcher, seems to be the same for 32 and 64 bit
    echo %0 :: - Python Launcher
    msiexec.exe /x {3B53E5B7-CFC4-401C-80E9-FF7591C58741} /quiet /qn

    :: wipe the Python directory
    echo %0 :: Removing the C:\Python38 Directory ...
    echo -----------------------------------------------------------------------
    if exist "C:\Python38" rd /s /q "C:\Python38"
    if %errorLevel%==0 (
        echo Successful
    ) else (
        echo Failed, please remove manually
    )

:CheckPython39
if not exist "\Python39" goto eof

:RemovePython39
    echo %0 :: Uninstalling Python 3.9 ...
    echo -----------------------------------------------------------------------
    :: 64 bit
    if exist "%LOCALAPPDATA%\Package Cache\{c1729c3e-67d4-4cc7-bab3-6dd84444ca47}" (
        echo %0 :: - 3.9.10 64bit
        "%LOCALAPPDATA%\Package Cache\{c1729c3e-67d4-4cc7-bab3-6dd84444ca47}\python-3.9.10-amd64.exe" /uninstall /quiet
    )

    :: 32 bit
    if exist "%LOCALAPPDATA%\Package Cache\{87d78079-31e7-4e20-ab9b-a57bf64b87d1}" (
        echo %0 :: - 3.8.8 32bit
        "%LOCALAPPDATA%\Package Cache\{87d78079-31e7-4e20-ab9b-a57bf64b87d1}\python-3.9.10" /uninstall /quiet
    )
    :: Python Launcher, seems to be the same for 32 and 64 bit
    echo %0 :: - Python Launcher
    msiexec.exe /x {0F246F5F-0282-4320-B735-7A5FDE7EA7D6} /quiet /qn

    :: wipe the Python directory
    echo %0 :: Removing the C:\Python39 Directory ...
    echo -----------------------------------------------------------------------
    if exist "C:\Python39" rd /s /q "C:\Python39"
    if %errorLevel%==0 (
        echo Successful
    ) else (
        echo Failed, please remove manually
    )

goto eof

:eof
echo.
echo =======================================================================
echo End of %0
echo =======================================================================
