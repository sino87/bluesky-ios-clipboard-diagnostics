@echo off
setlocal
set "TEMP=%LOCALAPPDATA%\Temp"
set "TMP=%TEMP%"
if not exist "%TEMP%\" exit /b 1
start "" "C:\Program Files (x86)\AltServer\AltServer.exe"
endlocal
