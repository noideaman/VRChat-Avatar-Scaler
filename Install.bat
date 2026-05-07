@echo off
setlocal EnableDelayedExpansion
title VRChat Avatar Scaler — Installer

:: ─────────────────────────────────────────────────────────────────────────────
::  VRChat Avatar Scaler — Installer
::  Checks for Python, installs dependencies, and creates a desktop shortcut.
:: ─────────────────────────────────────────────────────────────────────────────

set "SCRIPT_DIR=%~dp0"
set "SCRIPT=%SCRIPT_DIR%vrchat_avatar_scaler.pyw"
set "LAUNCHER=%SCRIPT_DIR%Launch Scaler (Silent).vbs"

call :header
echo  This installer will:
echo.
echo    1. Check that Python 3.10 or newer is installed
echo    2. Install all required Python packages
echo    3. Create a desktop shortcut for easy launching
echo.
echo  No files will be modified outside this folder and your desktop.
echo.
pause

:: ─── Check Python is available ───────────────────────────────────────────────
call :step "Checking for Python..."

where python >nul 2>&1
if errorlevel 1 (
    call :fail "Python was not found on this system."
    echo.
    echo  Python 3.10 or newer is required. Download it from:
    echo.
    echo    https://www.python.org/downloads/
    echo.
    echo  IMPORTANT: When installing Python, tick the box that says
    echo  "Add Python to PATH" before clicking Install.
    echo.
    goto :open_python_site
)

:: Identify the exact python.exe being used so all pip installs go to the right place
for /f "tokens=*" %%p in ('python -c "import sys; print(sys.executable)"') do set "PYTHON_EXE=%%p"
echo.
echo  Using Python at: !PYTHON_EXE!

:: Check version is at least 3.10
for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set "PYVER=%%v"
for /f "tokens=1,2 delims=." %%a in ("!PYVER!") do (
    set "PY_MAJOR=%%a"
    set "PY_MINOR=%%b"
)

if !PY_MAJOR! LSS 3 (
    call :fail "Python !PYVER! is too old. Version 3.10 or newer is required."
    goto :open_python_site
)
if !PY_MAJOR! EQU 3 if !PY_MINOR! LSS 10 (
    call :fail "Python !PYVER! is too old. Version 3.10 or newer is required."
    goto :open_python_site
)

call :ok "Found Python !PYVER!"

:: ─── Upgrade pip silently ────────────────────────────────────────────────────
call :step "Updating pip..."
"!PYTHON_EXE!" -m pip install --upgrade pip --quiet
if errorlevel 1 (
    call :warn "Could not upgrade pip — continuing anyway."
) else (
    call :ok "pip is up to date."
)

:: ─── Install required packages ───────────────────────────────────────────────
call :step "Installing required packages..."
echo.
echo  Installing: python-osc  pystray  Pillow  psutil
echo.

"!PYTHON_EXE!" -m pip install python-osc pystray Pillow psutil
if errorlevel 1 (
    call :fail "One or more packages failed to install."
    echo.
    echo  Try running this installer as Administrator, or check that
    echo  you have an active internet connection and try again.
    echo.
    goto :done_fail
)

call :ok "All packages installed successfully."

:: ─── Optional packages ───────────────────────────────────────────────────────
call :step "Installing optional packages..."
echo.
echo  Installing: pynput
echo  (Keyboard shortcuts — no administrator rights required.)
echo.

"!PYTHON_EXE!" -m pip install pynput
if errorlevel 1 (
    call :warn "pynput could not be installed — keyboard shortcuts will be unavailable."
) else (
    call :ok "pynput installed."
)

echo.
echo  Installing: tinyoscquery  zeroconf  requests
echo  (OSCQuery — automatic port negotiation with VRChat.)
echo  Note: tinyoscquery is installed directly from GitHub. Git must be installed.
echo  Using Hackebein's fork which includes a fix for clean process exit on Windows.
echo.

"!PYTHON_EXE!" -m pip install "git+https://github.com/Hackebein/tinyoscquery.git" zeroconf requests
if errorlevel 1 (
    call :warn "tinyoscquery could not be installed — OSCQuery will be unavailable."
    echo.
    echo  If Git is not installed, get it from: https://git-scm.com/downloads
    echo  Then re-run this installer.
) else (
    call :ok "tinyoscquery installed."
)

:: ─── Verify the main script exists ──────────────────────────────────────────
call :step "Checking for main script..."

if not exist "%SCRIPT%" (
    call :fail "vrchat_avatar_scaler.pyw not found in this folder."
    echo.
    echo  Make sure the installer is in the same folder as the script.
    goto :done_fail
)

call :ok "Found vrchat_avatar_scaler.pyw"

:: ─── Check VBS launcher exists, create if missing ───────────────────────────
if not exist "%LAUNCHER%" (
    call :step "Creating silent launcher..."
    (
        echo Set WshShell = CreateObject^("WScript.Shell"^)
        echo Set FSO = CreateObject^("Scripting.FileSystemObject"^)
        echo scriptDir = FSO.GetParentFolderName^(WScript.ScriptFullName^)
        echo WshShell.Run "pythonw """ ^& scriptDir ^& "\vrchat_avatar_scaler.pyw""", 0, False
    ) > "%LAUNCHER%"
    call :ok "Silent launcher created."
)

:: ─── Create desktop shortcut ─────────────────────────────────────────────────
call :step "Creating desktop shortcut..."

set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT=%DESKTOP%\VRChat Avatar Scaler.lnk"

:: Create shortcut via VBScript and set the RunAsAdministrator flag.
:: The flag lives in byte 21 of the shortcut file (0x20 = run as admin).
set "VBS_TEMP=%TEMP%\create_shortcut.vbs"
(
    echo Set ws = CreateObject^("WScript.Shell"^)
    echo Set sc = ws.CreateShortcut^("%SHORTCUT%"^)
    echo sc.TargetPath = "%LAUNCHER%"
    echo sc.WorkingDirectory = "%SCRIPT_DIR%"
    echo sc.Description = "VRChat Avatar Scaler"
    echo sc.Save
    echo.
    echo ' Set the Run As Administrator flag (byte 21, bit 0x20 in the shortcut file)
    echo Set fso = CreateObject^("Scripting.FileSystemObject"^)
    echo Set f = fso.OpenTextFile^("%SHORTCUT%", 1, False, -1^)
    echo Dim bytes^(^)
    echo ReDim bytes^(fso.GetFile^("%SHORTCUT%"^).Size - 1^)
    echo f.Close
    echo Set stream = CreateObject^("ADODB.Stream"^)
    echo stream.Type = 1
    echo stream.Open
    echo stream.LoadFromFile "%SHORTCUT%"
    echo Dim data
    echo data = stream.Read^(stream.Size^)
    echo stream.Close
    echo Mid^(data, 22, 1^) = Chr^(Asc^(Mid^(data, 22, 1^)^) Or 32^)
    echo Set stream2 = CreateObject^("ADODB.Stream"^)
    echo stream2.Type = 1
    echo stream2.Open
    echo stream2.Write data
    echo stream2.SaveToFile "%SHORTCUT%", 2
    echo stream2.Close
) > "!VBS_TEMP!"
cscript //nologo "!VBS_TEMP!" >nul 2>&1
del "!VBS_TEMP!" >nul 2>&1

if exist "%SHORTCUT%" (
    call :ok "Desktop shortcut created (marked Run as Administrator)."
) else (
    call :warn "Could not create desktop shortcut — launch via 'Launch Scaler (Silent).vbs' directly."
)

:: ─── Done ─────────────────────────────────────────────────────────────────────
echo.
echo ════════════════════════════════════════════════════════════════════════════
echo.
echo   Installation complete!
echo.
echo   You can now launch VRChat Avatar Scaler from your desktop shortcut,
echo   or by double-clicking:
echo.
echo     Launch Scaler (Silent).vbs
echo.
echo   Remember to enable OSC in VRChat:
echo     Action Menu ^> Options ^> OSC ^> Enabled
echo.
echo ════════════════════════════════════════════════════════════════════════════
echo.
pause
set /p "LAUNCH= Launch VRChat Avatar Scaler now? (Y/N): "
if /i "!LAUNCH!"=="Y" (
    cscript //nologo "%LAUNCHER%" >nul 2>&1
)
goto :eof

:: ─── Helpers ─────────────────────────────────────────────────────────────────
:header
echo.
echo ════════════════════════════════════════════════════════════════════════════
echo   VRChat Avatar Scaler — Installer
echo ════════════════════════════════════════════════════════════════════════════
echo.
goto :eof

:step
echo.
echo  ^>^> %~1
goto :eof

:ok
echo     [OK]  %~1
goto :eof

:warn
echo     [!!]  %~1
goto :eof

:fail
echo.
echo     [ERROR]  %~1
goto :eof

:open_python_site
set /p "OPEN= Open the Python download page now? (Y/N): "
if /i "!OPEN!"=="Y" start https://www.python.org/downloads/
echo.
echo  Re-run this installer after Python is installed.
echo.
pause
goto :eof

:done_fail
echo.
echo  Installation did not complete successfully. See errors above.
echo.
pause
goto :eof
