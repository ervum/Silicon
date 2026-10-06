@echo off
if "%~1"=="" (
    python "%~dp0..\Silicon.py" Bidirectional
) else (
    python "%~dp0..\Silicon.py" %*
)
