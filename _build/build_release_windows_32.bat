@rem Script to build for Windows using Visual Studio.

@echo OFF

if not defined TOOLCHAIN (
  echo Using latest Visual Studio install... 1>&2
  call %~dp0\scripts\vc.bat latest windows x86
) else (
  call %~dp0\scripts\vc.bat %TOOLCHAIN% windows x86
)

if not "%ERRORLEVEL%"=="0" (
  echo Could not setup environment to compile for Windows.
  exit /B 1
)

call %~dp0\build_release_windows_any.bat
