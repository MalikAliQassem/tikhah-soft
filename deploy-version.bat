@echo off
setlocal enabledelayedexpansion

title Advanced Version Deployer

echo ========================================
echo      Advanced Version Deployment Tool
echo ========================================
echo.

:: Create releases directory if not exists
if not exist "whatsapp\releases" (
    echo Creating 'releases' directory...
    mkdir "whatsapp\releases"
)

:: Fix DATE format
for /f "tokens=1-3 delims=/.- " %%a in ('date /t') do (
    if "%%a" gtr "31" (
        set DATE=%%a-%%b-%%c
    ) else (
        set DATE=%%c-%%a-%%b
    )
)

:: Fix TIME format (support AM/PM)
for /f "tokens=1,2 delims= " %%a in ('time /t') do (
    set T1=%%a
    set T2=%%b
)

set TIME=%T1%
if defined T2 (
    set TIME=%T1% %T2%
)

:: Input VERSION
:input_version
set /p VERSION=Enter version number (e.g., 1.0.1): 
if "%VERSION%"=="" (
    echo Please enter a version number!
    goto input_version
)

:: Input notes
set /p RELEASE_NOTES=Enter release notes (optional): 

set VERSION_DIR_BASE=whatsapp
set VERSION_DIR=whatsapp\releases\v%VERSION%
set TIMESTAMP=%DATE% %TIME%

if exist "%VERSION_DIR%" (
    echo Version exists. Overwrite?
    choice /C YN
    if errorlevel 2 exit /b 1
    rmdir "%VERSION_DIR%" /S /Q
)

mkdir "%VERSION_DIR%"

echo Copying files...

set SOURCE_DIR=..\filesRelease
set FILE_COUNT=0
set COPIED_COUNT=0

:: Count files
:: Count files
for /f %%i in ('dir /b "%SOURCE_DIR%\*" ^| find /c /v ""') do set FILE_COUNT=%%i

if %FILE_COUNT%==0 (
    echo No files found in %SOURCE_DIR%
    pause
    exit /b 1
)

echo Total files: %FILE_COUNT%


echo Total files: %FILE_COUNT%
echo DEBUG: FILE_COUNT=%FILE_COUNT%
echo DEBUG: SOURCE_DIR=%SOURCE_DIR%
echo.

for %%f in ("%SOURCE_DIR%\*") do (
    set /a COPIED_COUNT+=1
    @REM set /a PERCENT=(!COPIED_COUNT!*100)/%FILE_COUNT%
    echo Copying [!COPIED_COUNT!%%]: %%~nxf
    copy "%%~f" "%VERSION_DIR%\%%~nxf" >nul
)





:: Create version file
echo Version: v%VERSION% > "%VERSION_DIR%\version.info"
echo Build Date: %TIMESTAMP% >> "%VERSION_DIR%\version.info"
echo Release Notes: %RELEASE_NOTES% >> "%VERSION_DIR%\version.info"

:: Fix GitHub URL
set URL_GITHUB_DIR=https://github.com/MalikAliQassem/tikhah-soft/raw/main/whatsapp/releases/v%VERSION%/SetupThirdParty.zip

:: Update AutoUpdater.xml
set AUTOUPDATER_FILE=%VERSION_DIR_BASE%\AutoUpdater.xml

if not exist "%AUTOUPDATER_FILE%" (
    call :create_autoupdater
) else (
    call :update_autoupdater
)

echo ========================================
echo DEPLOYMENT SUMMARY
echo ========================================
echo Version: v%VERSION%
echo Directory: %VERSION_DIR%
echo Timestamp: %TIMESTAMP%
echo Files Copied: !COPIED_COUNT!
echo Release Notes: %RELEASE_NOTES%
echo ========================================

choice /C YN /M "Commit to Git?"
if errorlevel 1 (
    git add .
    git commit -m "Release v%VERSION% - %RELEASE_NOTES%"
)

pause
exit /b 0



:create_autoupdater
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<item^>
echo   ^<version^>%VERSION%^</version^>
echo   ^<url^>%URL_GITHUB_DIR%^</url^>
echo   ^<changelog^>https://github.com/MalikAliQassem/tikhah-soft/raw/main/whatsapp/Note.html^</changelog^>
echo ^</item^>
) > "%AUTOUPDATER_FILE%"

echo Created new AutoUpdater.xml
goto :eof


:update_autoupdater
echo File = %AUTOUPDATER_FILE%
echo Version = %VERSION%
echo URL = %URL_GITHUB_DIR%
if exist %AUTOUPDATER_FILE% (
   echo FOUND FILE
) else (
   echo FILE NOT FOUND
)
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<item^>
echo   ^<version^>%VERSION%^</version^>
echo   ^<url^>%URL_GITHUB_DIR%^</url^>
echo   ^<changelog^>https://github.com/MalikAliQassem/tikhah-soft/raw/main/whatsapp/Note.html^</changelog^>
echo ^</item^>
) > "%AUTOUPDATER_FILE%"

echo Updated AutoUpdater.xml
goto :eof
