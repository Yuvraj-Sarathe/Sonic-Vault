@echo off
REM Build SonicVault for Windows (Release) and create installer
REM Any developer can run this after cloning the repo.

set PROJECT=%~dp0
set RELEASE_DIR=%PROJECT%build\windows\x64\runner\Release

echo Building SonicVault --release...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo Build failed. Make sure Flutter SDK and Visual Studio Build Tools are installed.
    exit /b %errorlevel%
)

echo.
echo Build complete!
echo Binary at: %RELEASE_DIR%\sonicvault.exe
echo.
echo To create the installer:
echo   1. Download Inno Setup from https://jrsoftware.org/isdl.php
echo   2. Open installer\installer.iss in Inno Setup Compiler
echo   3. Click Build -^> Compile
echo.
echo Or compile from command line:
echo   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\installer.iss
echo.
pause
