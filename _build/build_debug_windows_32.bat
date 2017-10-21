@rem Script to build for Windows using Visual Studio.

@echo OFF
@setlocal enabledelayedexpansion

@rem Find and use latest Visual Studio install unless overridden.

if not defined TOOLCHAIN (
  echo Using latest Visual Studio install... 1>&2
  call %~dp0\scripts\vc.bat latest windows x86
) else (
  echo Using Visual Studio %TOOLCHAIN%... 1>&2
  call %~dp0\scripts\vc.bat %TOOLCHAIN% windows x86
)

if not "%ERRORLEVEL%"=="0" (
  echo Could not setup environment to compile for Windows.
  exit /B 1
)

@rem We use the preprocessor to drive a unity build.

mkdir _build 2>NUL
mkdir _build\obj 2>NUL
mkdir _build\bin 2>NUL
mkdir _build\lib 2>NUL

call _build\scripts\unity.bat src > _build\unity.cc

set PROJECT_INCLUDES=/I"include/"
set PROJECT_LIBRARIES=kernel32.lib user32.lib

set PROJECT_COMPILE=cl /nologo /c /W4
set PROJECT_LINK=link /nologo /manifest:no

set PROJECT_BINARY=project_debug_windows_32.exe

@rem Unoptimized build.
set PROJECT_COMPILE=%PROJECT_COMPILE% /arch:IA32 /favor:blend /fp:precise /fp:except /Od
set PROJECT_LINK=%PROJECT_LINK% /machine:X86

@rem Generate debug symbols.
set PROJECT_COMPILE=%PROJECT_COMPILE% /Zi /FS
set PROJECT_LINK=%PROJECT_LINK% /DEBUG

@rem Statically link to debug version of CRT.
set PROJECT_COMPILE=%PROJECT_COMPILE% /MTd

@rem Save us from ourselves.
set PROJECT_COMPILE=%PROJECT_COMPILE% /DCONFIGURATION=CONFIGURATION_DEBUG
set PROJECT_COMPILE=%PROJECT_COMPILE% /D_DEBUG=1 /D_HAS_ITERATOR_DEBUGGING=1
set PROJECT_COMPILE=%PROJECT_COMPILE% /RTCsu /GS

@rem Disable runtime type information and exceptions.
set PROJECT_COMPILE=%PROJECT_COMPILE% /EHs-c- /GR- /D_HAS_EXCEPTIONS=0

@rem Shut up complaints about usage of potentially unsafe methods.
set PROJECT_COMPILE=%PROJECT_COMPILE% /D_SCL_SECURE_NO_WARNINGS /D_CRT_SECURE_NO_DEPRECATE

@rem Shut up complaints about usage of Microsoft-specific CRT functionality.
set PROJECT_COMPILE=%PROJECT_COMPILE% /D_CRT_NONSTDC_NO_DEPRECATE

@rem Disable address space layout randomization to ease debugging.
set PROJECT_LINK=%PROJECT_LINK% /DYNAMICBASE:NO

@echo ON

%PROJECT_COMPILE% %PROJECT_INCLUDES% /Fo_build\obj\project_debug_windows_32.obj _build\unity.cc
%PROJECT_LINK% /out:_build\bin\%PROJECT_BINARY% _build\obj\project_debug_windows_32.obj %PROJECT_LIBRARIES%
