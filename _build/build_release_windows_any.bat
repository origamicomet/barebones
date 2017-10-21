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

call _build\scripts\unity.bat src > _build\project_release_windows_%PROJECT_SUFFIX%.cc

set PROJECT_INCLUDES=/I"include/"
set PROJECT_LIBRARIES=kernel32.lib user32.lib

set PROJECT_COMPILE=cl /nologo /c /W4
set PROJECT_LINK=link /nologo /manifest:no

set PROJECT_BINARY=project_release_windows_%PROJECT_SUFFIX%.exe

@rem Setup architecture based on environment setup by caller.
if %TARGET%==x86 (
  set PROJECT_COMPILE=%PROJECT_COMPILE% /arch:SSE2
  set PROJECT_LINK=%PROJECT_LINK% /machine:X86
)
if %TARGET%==amd64 (
  set PROJECT_COMPILE=%PROJECT_COMPILE%
  set PROJECT_LINK=%PROJECT_LINK% /machine:X64
)

@rem Optimized build.
set PROJECT_COMPILE=%PROJECT_COMPILE% /favor:blend /fp:fast /O2

@rem Generate debug symbols.
set PROJECT_COMPILE=%PROJECT_COMPILE% /Zi /FS
set PROJECT_LINK=%PROJECT_LINK% /DEBUG

@rem Statically link to release version of CRT.
set PROJECT_COMPILE=%PROJECT_COMPILE% /MT

@rem Save us from ourselves.
set PROJECT_COMPILE=%PROJECT_COMPILE% /DPROJECT_CONFIGURATION=PROJECT_CONFIGURATION_RELEASE
set PROJECT_COMPILE=%PROJECT_COMPILE% /DNDEBUG=1 /D_HAS_ITERATOR_DEBUGGING=0

@rem Disable runtime type information and exceptions.
set PROJECT_COMPILE=%PROJECT_COMPILE% /EHs-c- /GR- /D_HAS_EXCEPTIONS=0

@rem Shut up complaints about usage of potentially unsafe methods.
set PROJECT_COMPILE=%PROJECT_COMPILE% /D_SCL_SECURE_NO_WARNINGS /D_CRT_SECURE_NO_DEPRECATE

@rem Shut up complaints about usage of Microsoft-specific CRT functionality.
set PROJECT_COMPILE=%PROJECT_COMPILE% /D_CRT_NONSTDC_NO_DEPRECATE

%PROJECT_COMPILE% %PROJECT_INCLUDES% /Fd_build\obj\project_release_windows_%PROJECT_SUFFIX%.pdb /Fo_build\obj\project_release_windows_%PROJECT_SUFFIX%.obj _build\project_release_windows_%PROJECT_SUFFIX%.cc
%PROJECT_LINK% /out:_build\bin\%PROJECT_BINARY% _build\obj\project_release_windows_%PROJECT_SUFFIX%.obj %PROJECT_LIBRARIES%
