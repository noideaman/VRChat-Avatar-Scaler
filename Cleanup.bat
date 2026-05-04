@echo off
setlocal EnableDelayedExpansion
title VRChat Avatar Scaler — Cleanup

:: ─────────────────────────────────────────────────────────────────────────────
::  VRChat Avatar Scaler — Cleanup Utility
::
::  Removes any leftover auto-launch entries that may have been created by
::  earlier versions of this application, including:
::
::    • SteamVR app registry entries (caused auto-launch with SteamVR)
::    • Windows startup folder shortcuts
::
::  This does NOT uninstall the scaler itself or remove any Python packages.
:: ─────────────────────────────────────────────────────────────────────────────

set "SCRIPT_DIR=%~dp0"

echo.
echo ════════════════════════════════════════════════════════════════════════════
echo   VRChat Avatar Scaler — Cleanup Utility
echo ════════════════════════════════════════════════════════════════════════════
echo.
echo  This will remove auto-launch entries created by earlier versions.
echo  The scaler itself will not be affected.
echo.
pause

:: ─── 1. Remove SteamVR app registry entry ────────────────────────────────────
echo.
echo  ^>^> Removing SteamVR app registry entry...
echo.

:: The SteamVR application manifest is stored in openvrpaths.vrpath.
:: Earlier versions of this app called addApplicationManifest(temporary=False)
:: which wrote the vrmanifest path into SteamVR's persistent app list.
:: We remove it by deleting the vrmanifest file (SteamVR will drop the entry
:: on next launch) and by removing the entry from the SteamVR app config.

set "VRMANIFEST=%SCRIPT_DIR%vrchat_avatar_scaler.vrmanifest"
set "ACTIONS_JSON=%SCRIPT_DIR%actions.json"
set "BINDINGS_JSON=%SCRIPT_DIR%bindings_knuckles.json"

if exist "%VRMANIFEST%" (
    del /f /q "%VRMANIFEST%"
    echo     [OK]  Deleted vrchat_avatar_scaler.vrmanifest
) else (
    echo     [--]  vrchat_avatar_scaler.vrmanifest not found ^(already clean^)
)

if exist "%ACTIONS_JSON%" (
    del /f /q "%ACTIONS_JSON%"
    echo     [OK]  Deleted actions.json
) else (
    echo     [--]  actions.json not found ^(already clean^)
)

if exist "%BINDINGS_JSON%" (
    del /f /q "%BINDINGS_JSON%"
    echo     [OK]  Deleted bindings_knuckles.json
) else (
    echo     [--]  bindings_knuckles.json not found ^(already clean^)
)

:: Remove the app from SteamVR's internal app config if Python + openvr available
python -c "
try:
    import openvr
    openvr.init(openvr.VRApplication_Overlay)
    apps = openvr.IVRApplications()
    try:
        apps.removeApplicationManifest(r'%VRMANIFEST%')
        print('SteamVR registry entry removed.')
    except Exception as e:
        print(f'Could not remove SteamVR entry via API: {e}')
    openvr.shutdown()
except Exception as e:
    print(f'openvr not available or SteamVR not running: {e}')
    print('If SteamVR still auto-launches the scaler, do this manually:')
    print('  SteamVR Settings -> Apps -> find VRChat Avatar Scaler -> remove it')
" 2>nul

echo.
echo  If SteamVR still auto-launches the scaler after running this, open SteamVR
echo  manually and go to: Settings ^> Apps
echo  Find "VRChat Avatar Scaler" and remove or disable it from that list.
echo.

:: ─── 2. Check and remove Windows startup folder shortcut ─────────────────────
echo.
echo  ^>^> Checking Windows startup folder...
echo.

set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT1=%STARTUP%\VRChat Avatar Scaler.lnk"
set "SHORTCUT2=%STARTUP%\Launch Scaler (Silent).lnk"

set "FOUND_STARTUP=0"

if exist "%SHORTCUT1%" (
    set "FOUND_STARTUP=1"
    echo     Found: VRChat Avatar Scaler.lnk in startup folder
)
if exist "%SHORTCUT2%" (
    set "FOUND_STARTUP=1"
    echo     Found: Launch Scaler (Silent).lnk in startup folder
)

if "!FOUND_STARTUP!"=="1" (
    echo.
    set /p "REMOVE_STARTUP= Remove startup folder shortcut(s)? (Y/N): "
    if /i "!REMOVE_STARTUP!"=="Y" (
        if exist "%SHORTCUT1%" (
            del /f /q "%SHORTCUT1%"
            echo     [OK]  Removed VRChat Avatar Scaler.lnk
        )
        if exist "%SHORTCUT2%" (
            del /f /q "%SHORTCUT2%"
            echo     [OK]  Removed Launch Scaler (Silent).lnk
        )
    ) else (
        echo     [--]  Startup shortcuts left in place.
    )
) else (
    echo     [--]  No startup folder shortcuts found ^(already clean^)
)

:: ─── 3. Check desktop shortcut (informational only) ──────────────────────────
echo.
echo  ^>^> Checking desktop shortcut...
echo.

set "DESKTOP=%USERPROFILE%\Desktop"
if exist "%DESKTOP%\VRChat Avatar Scaler.lnk" (
    echo     Found: Desktop shortcut exists.
    echo     The desktop shortcut was NOT removed.
    echo     If you want to remove it, right-click it and choose Delete.
) else (
    echo     [--]  No desktop shortcut found.
)

:: ─── Done ─────────────────────────────────────────────────────────────────────
echo.
echo ════════════════════════════════════════════════════════════════════════════
echo   Cleanup complete.
echo.
echo   Restart SteamVR if it was running to apply the registry changes.
echo ════════════════════════════════════════════════════════════════════════════
echo.
pause
