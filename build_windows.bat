@echo off
REM Build SonicVault for Windows
REM Uses junction to avoid space-in-path issues with native plugins

set FLUTTER_ROOT=C:\Users\yuvra\AppData\Local\Temp\flutter
set JUNCTION=C:\Users\yuvra\AppData\Local\Temp\sonicvault
set PROJECT=C:\Users\yuvra\OneDrive\Desktop\Yuvraj\Sonic Vault

if not exist %JUNCTION% (
    mklink /J %JUNCTION% "%PROJECT%"
)

cd /d %JUNCTION%
echo Building SonicVault --debug...
call flutter build windows --debug
echo Build complete.
pause
