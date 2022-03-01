@ echo off
:: Script for starting the Salt-Api
:: Accepts all parameters that Salt-Api accepts

:: Define Variables
Set SaltDir=%~dp0
Set SaltDir=%SaltDir:~0,-1%
Set Salt=%SaltDir%\bin\salt.exe

:: Launch Script
"%Salt%" api %*
