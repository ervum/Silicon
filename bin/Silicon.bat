@echo off
if "%~1"=="" (
    python "%~dp0..\Silicon.py"
) else (
    python "%~dp0..\Silicon.py" %*
)
