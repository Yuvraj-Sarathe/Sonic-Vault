@echo off
REM Build SonicVault for Windows (Release)
REM Uses junction to avoid space-in-path issues with native plugins

set FLUTTER_ROOT=C:\Users\yuvra\AppData\Local\Temp\flutter
set JUNCTION=C:\Users\yuvra\AppData\Local\Temp\sonicvault
set PROJECT=C:\Users\yuvra\OneDrive\Desktop\Yuvraj\Sonic Vault

if not exist %JUNCTION% (
    mklink /J %JUNCTION% "%PROJECT%"
)

cd /d %JUNCTION%
echo Building SonicVault --release...
call flutter build windows --release
xcopy /E /I /Y build\windows\x64\runner\Release "%PROJECT%\release"
echo Build complete. Binary at "%PROJECT%\release\sonicvault.exe"
pause
