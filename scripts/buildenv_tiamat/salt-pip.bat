@ echo off
:: Script for invoking pip in the Salt environment
:: Accepts all parameters that pip accepts

:: Define Variables
Set SaltDir=%~dp0
Set SaltDir=%SaltDir:~0,-1%
Set Salt=%SaltDir%\bin\salt.exe

:: Launch Script
"%Salt%" pip %*
