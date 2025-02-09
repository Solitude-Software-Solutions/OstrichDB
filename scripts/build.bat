@echo off
setlocal enabledelayedexpansion

:: Get the directory of this script
set "SCRIPT_DIR=%~dp0"

:: Change to the project root directory
cd /d "%SCRIPT_DIR%.."

:: Change to the src directory
cd src

:: Set executable extension for Windows
set "EXECUTABLE_EXT=.exe"

:: Build the project in the src directory
echo Building OstrichDB For Windows...
odin build main

:: Check if build was successful
if %ERRORLEVEL% equ 0 (
    echo [32mBuild successful[0m

    :: Try to create bin directory and move the executable
    if not exist "..\bin" mkdir "..\bin"
    move "main%EXECUTABLE_EXT%" "..\bin\" >nul 2>&1
    if %ERRORLEVEL% equ 0 (
        cd ..\bin
    ) else (
        echo [31mCould not move executable to bin directory. Running from src.[0m
    )

    :: Run OstrichDB
    main%EXECUTABLE_EXT%

    :: Capture the exit code
    set EXIT_CODE=%ERRORLEVEL%

    :: Check the exit code
    if !EXIT_CODE! neq 0 (
        echo [31mOstrichDB exited with code !EXIT_CODE![0m
    )

    :: Return to the project root directory
    cd /d "%SCRIPT_DIR%.."
) else (
    echo [31mBuild failed[0m
)

:: Restore terminal echo settings
stty echo

endlocal
@echo on
