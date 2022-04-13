@ echo off
:: Script for invoking salt-key
:: Accepts all parameters that salt-key accepts

:: Define Variables
Set SaltDir=%~dp0
Set SaltDir=%SaltDir:~0,-1%
Set Salt=%SaltDir%\bin\salt.exe

:: Launch Script
"%Salt%" key %*
