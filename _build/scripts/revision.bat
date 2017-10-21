@echo off

for /F "usebackq tokens=1" %%r in (`call %~dp0\git.bat rev-parse HEAD`) do (
  <NUL set /p=%%r
)
