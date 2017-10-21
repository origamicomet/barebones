@rem Forwards to `7z` if in path, or to a local copy of 7-Zip if not found.

@echo OFF
@setlocal enabledelayedexpansion

where /Q 7z

if "%ERRORLEVEL%"=="0" (
  7z %*
  exit /B !ERRORLEVEL!
) else (
  set _7zip=%~dp0\..\tools\cache\7za.exe
  set _7zipVer=16.04
  set _7zipSource=https://github.com/origamicomet/barebones/releases/download/v0.1.0/7za.exe

  if not exist !_7zip! (
    if defined DO_NOT_FETCH_TOOLS (
      echo Could not find 7-Zip!
      exit /B 1
    ) else (
      PowerShell.exe -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -File %~dp0\download.ps1 !_7zipSource! !_7zip!

      if not "!ERRORLEVEL!"=="0" (
        echo Failed to fetch 7-Zip for Windows!
        exit /B 1
      )
    )
  )

  !_7zip! %*
)

