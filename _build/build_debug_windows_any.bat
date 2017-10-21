@rem Script to build for Windows using Visual Studio.

@echo OFF
@setlocal enabledelayedexpansion

@rem We use the preprocessor to drive a unity build.

mkdir _build 2>NUL
mkdir _build\obj 2>NUL
mkdir _build\bin 2>NUL
mkdir _build\lib 2>NUL

@rem Suffix based on environment setup by caller.
if %TARGET%==x86 set PROJECT_SUFFIX=32
if %TARGET%==amd64 set PROJECT_SUFFIX=64

call _build\scripts\unity.bat src > _build\project_debug_windows_%PROJECT_SUFFIX%.cc

set PROJECT_INCLUDES=/I"include/"
set PROJECT_LIBRARIES=kernel32.lib user32.lib

set PROJECT_COMPILE=cl /nologo /c /W4
set PROJECT_LINK=link /nologo /manifest:no

set PROJECT_BINARY=project_debug_windows_%PROJECT_SUFFIX%.exe

@rem Setup architecture based on environment setup by caller.
if %TARGET%==x86 (
  set PROJECT_COMPILE=%PROJECT_COMPILE% /arch:IA32
  set PROJECT_LINK=%PROJECT_LINK% /machine:X86
)
if %TARGET%==amd64 (
  set PROJECT_COMPILE=%PROJECT_COMPILE%
  set PROJECT_LINK=%PROJECT_LINK% /machine:X64
)

@rem Unoptimized build.
set PROJECT_COMPILE=%PROJECT_COMPILE% /favor:blend /fp:precise /fp:except /Od

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

%PROJECT_COMPILE% %PROJECT_INCLUDES% /Fo_build\obj\project_debug_windows_%PROJECT_SUFFIX%.obj _build\project_debug_windows_%PROJECT_SUFFIX%.cc
%PROJECT_LINK% /out:_build\bin\%PROJECT_BINARY% _build\obj\project_debug_windows_%PROJECT_SUFFIX%.obj %PROJECT_LIBRARIES%
