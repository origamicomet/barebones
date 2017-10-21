@rem Forwards to `git` if in path, or to a local copy of Git for Windows if
@rem not found.

@echo OFF
@setlocal enabledelayedexpansion

where /Q git

if "%ERRORLEVEL%"=="0" (
  git %*
  exit /B !ERRORLEVEL!
) else (
  set _GitForWindows=%~dp0\..\tools\cache\git-for-windows
  set _GitForWindowsVer=2.14.2
  set _GitForWindowsSource=https://github.com/git-for-windows/git/releases/download/v!_GitForWindowsVer!.windows.1/PortableGit-!_GitForWindowsVer!-32-bit.7z.exe

  if not exist !_GitForWindows! (
    if defined DO_NOT_FETCH_TOOLS (
      echo Could not find Git!
      exit /B 1
    ) else (
      @rem Download.

      PowerShell.exe -NoProfile -NonInteractive -ExecutionPolicy Unrestricted -File %~dp0\download.ps1 !_GitForWindowsSource! !_GitForWindows!.7z.exe

      if not "!ERRORLEVEL!"=="0" (
        echo Failed to fetch Git for Windows from Github!
        exit /B 1
      )

      @rem Extract.

      %~dp0\7z.bat e -o!_GitForWindows! !_GitForWindows!.7z.exe

      @rem Post install, otherwise Git for Windows won't work.

      cmd /c "git-bash.exe --no-needs-console --hide --no-cd --command=!_GitForWindows!\post-install.cmd"
    )
  )

  set gitdir=!_GitForWindows!

  "!_GitForWindows!\cmd\git.exe" %*
)
