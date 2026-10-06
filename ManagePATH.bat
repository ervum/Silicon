@echo off
setlocal enabledelayedexpansion

:: Resolve absolute path to Silicon's bin directory
set "BIN_DIR=%~dp0bin"
for %%I in ("%BIN_DIR%") do set "BIN_DIR=%%~fI"

:: If an argument was passed, execute directly
if /i "%~1"=="add" goto :DoAdd
if /i "%~1"=="install" goto :DoAdd
if /i "%~1"=="remove" goto :DoRemove
if /i "%~1"=="uninstall" goto :DoRemove
if /i "%~1"=="status" goto :DoStatus
if /i "%~1"=="check" goto :DoStatus

:Menu
cls
echo ====================================================
echo          Silicon PATH Environment Manager
echo ====================================================
echo Silicon bin directory:
echo   %BIN_DIR%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$bin = '%BIN_DIR%';" ^
    "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
    "$paths = ($userPath -split ';') | Where-Object { $_ -ne '' };" ^
    "if ($paths -contains $bin) {" ^
    "    Write-Host '  Status: [INSTALLED] Silicon is in your User PATH.' -ForegroundColor Green;" ^
    "} else {" ^
    "    Write-Host '  Status: [NOT INSTALLED] Silicon is not in your User PATH.' -ForegroundColor Yellow;" ^
    "}"

echo.
echo  [1] Add Silicon to User PATH
echo  [2] Remove Silicon from User PATH
echo  [3] Check PATH Status
echo  [4] Exit
echo.
set /p "CHOICE=Enter choice (1-4): "

if "%CHOICE%"=="1" goto :DoAdd
if "%CHOICE%"=="2" goto :DoRemove
if "%CHOICE%"=="3" goto :DoStatus
if "%CHOICE%"=="4" goto :End
goto :Menu

:DoAdd
echo.
echo [Silicon] Adding to User PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$bin = '%BIN_DIR%';" ^
    "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
    "$paths = ($userPath -split ';') | Where-Object { $_ -ne '' };" ^
    "if ($paths -contains $bin) {" ^
    "    Write-Host '[Silicon] Silicon is already in your User PATH!' -ForegroundColor Yellow;" ^
    "} else {" ^
    "    $newPath = ($paths + $bin) -join ';';" ^
    "    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User');" ^
    "    Write-Host '[Silicon] Successfully added Silicon to User PATH!' -ForegroundColor Green;" ^
    "    Write-Host 'Target: ' -NoNewline; Write-Host $bin -ForegroundColor Cyan;" ^
    "    Write-Host '[Silicon] NOTE: Restart any open command prompts or IDE terminals for changes to take effect.' -ForegroundColor Cyan;" ^
    "}"
echo.
if "%~1"=="" pause
goto :End

:DoRemove
echo.
echo [Silicon] Removing from User PATH...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$bin = '%BIN_DIR%';" ^
    "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
    "$paths = ($userPath -split ';') | Where-Object { $_ -ne '' -and $_ -ne $bin -and $_ -ne ($bin + '\') };" ^
    "$newPath = $paths -join ';';" ^
    "[Environment]::SetEnvironmentVariable('Path', $newPath, 'User');" ^
    "Write-Host '[Silicon] Successfully removed Silicon from User PATH!' -ForegroundColor Green;" ^
    "Write-Host '[Silicon] NOTE: Restart any open command prompts or IDE terminals for changes to take effect.' -ForegroundColor Cyan;"
echo.
if "%~1"=="" pause
goto :End

:DoStatus
echo.
echo [Silicon] Current User PATH Entries:
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$bin = '%BIN_DIR%';" ^
    "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User');" ^
    "$paths = ($userPath -split ';') | Where-Object { $_ -ne '' };" ^
    "foreach ($p in $paths) {" ^
    "    if ($p -eq $bin) {" ^
    "        Write-Host ('  - ' + $p + ' [SILICON]') -ForegroundColor Green;" ^
    "    } else {" ^
    "        Write-Host ('  - ' + $p);" ^
    "    }" ^
    "};" ^
    "Write-Host '';" ^
    "if ($paths -contains $bin) {" ^
    "    Write-Host 'Silicon is currently in User PATH.' -ForegroundColor Green;" ^
    "} else {" ^
    "    Write-Host 'Silicon is NOT in User PATH.' -ForegroundColor Yellow;" ^
    "}"
echo.
if "%~1"=="" pause
goto :End

:End
