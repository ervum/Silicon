@echo off
setlocal enabledelayedexpansion
title Silicon Launcher

:: Directory where this shortcut file is located (e.g. your Desktop or project workspace)
set "LAUNCH_DIR=%~dp0"
if "%LAUNCH_DIR:~-1%"=="\" set "LAUNCH_DIR=%LAUNCH_DIR:~0,-1%"

:: Target Game directory created right next to this shortcut launcher
set "GAME_TARGET=%LAUNCH_DIR%\Game"

echo ====================================================
echo                 Silicon Launcher
echo ====================================================
echo Workspace Location : %LAUNCH_DIR%
echo Game Folder Target : %GAME_TARGET%
echo ====================================================
echo.

:: 1. Check if running inside the Silicon repository itself
if exist "%~dp0bin\Silicon.bat" (
    echo [Silicon] Found Silicon in local folder: %~dp0bin\Silicon.bat
    echo [Silicon] Launching Bidirectional synchronization...
    echo.
    call "%~dp0bin\Silicon.bat" Bidirectional -p "%GAME_TARGET%" %*
    goto :Finish
)

:: 2. Check if Silicon.bat is available on the system PATH
where.exe Silicon.bat >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo [Silicon] Found Silicon.bat in system PATH.
    echo [Silicon] Launching Bidirectional synchronization...
    echo.
    call Silicon.bat Bidirectional -p "%GAME_TARGET%" %*
    goto :Finish
)

:: 3. Check known Silicon installation locations
if exist "C:\Dev\Silicon\bin\Silicon.bat" (
    echo [Silicon] Found Silicon in C:\Dev\Silicon.
    echo [Silicon] Launching Bidirectional synchronization...
    echo.
    call "C:\Dev\Silicon\bin\Silicon.bat" Bidirectional -p "%GAME_TARGET%" %*
    goto :Finish
)

if exist "c:\Users\Ervum\OneDrive\Documents\Projects\Roblox\Silicon\bin\Silicon.bat" (
    echo [Silicon] Found Silicon in project repository.
    echo [Silicon] Launching Bidirectional synchronization...
    echo.
    call "c:\Users\Ervum\OneDrive\Documents\Projects\Roblox\Silicon\bin\Silicon.bat" Bidirectional -p "%GAME_TARGET%" %*
    goto :Finish
)

:: 4. If not found, provide helpful instructions
echo [ERROR] Could not find Silicon.bat in PATH or standard directories!
echo.
echo To fix this:
echo   1. Run 'ManagePATH.bat' (or 'AddSiliconToPATH.bat') inside your Silicon folder.
echo   2. Or install/move Silicon to 'C:\Dev\Silicon'.
echo.
pause
exit /b 1

:Finish
if %ERRORLEVEL% neq 0 (
    echo.
    echo [Silicon] Exited with code %ERRORLEVEL%.
    pause
)
