@ echo off
:: Script for starting the Salt-Minion
:: Accepts all parameters that Salt-Minion Accepts

:: Define Variables
Set SaltDir=%~dp0
Set SaltDir=%SaltDir:~0,-1%
Set Salt=%SaltDir%\bin\salt.exe

:: Stop the Salt Minion service
net stop salt-minion

:: Launch Script
"%Salt%" minion -l debug
