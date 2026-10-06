@echo off

REM Runs the Python script and passes command-line arguments to it. Defaults to Bidirectional if no command is specified.
if "%~1"=="" (
    python Silicon.py Bidirectional
) else (
    python Silicon.py %*
)

REM Keeps the window open in order for the user to see the output.
pause
