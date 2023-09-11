@echo off
set IMAGE=%1
tasklist /FI "IMAGENAME eq %IMAGE%" | find "%IMAGE%" > NUL
if %errorlevel% == 0 (
    echo true
    exit
) else (
    echo false
    cd .
    exit
)