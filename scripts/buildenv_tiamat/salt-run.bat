@ echo off
:: Script for invoking salt-run
:: Accepts all parameters that salt-run accepts

:: Define Variables
Set SaltDir=%~dp0
Set SaltDir=%SaltDir:~0,-1%
Set Salt=%SaltDir%\bin\salt.exe

:: Launch Script
"%Salt%" run %*
