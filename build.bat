@echo off
if not exist dist mkdir dist
powershell -ExecutionPolicy Bypass -File "%~dp0build.ps1"
pause
