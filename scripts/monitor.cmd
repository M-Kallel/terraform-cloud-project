@echo off
setlocal EnableDelayedExpansion
if "%~1"=="" exit /b 1
for /L %%i in (1,1,120) do (
 echo !date! !time!
 curl.exe -sS --max-time 4 "%~1/"
 timeout /t 2 /nobreak >nul
)
