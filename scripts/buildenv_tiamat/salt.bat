@ echo off
:: Script for starting the Salt CLI
:: Accepts all parameters that Salt CLI accepts

:: Define Variables
Set SaltDir=%~dp0
Set SaltDir=%SaltDir:~0,-1%
Set Salt=%SaltDir%\bin\salt.exe

:: Launch Script
"%Salt%" %*
