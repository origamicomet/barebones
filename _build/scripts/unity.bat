@rem Recursively walks directories to generate a unity build file.

for %%D in (%*) do (
  for /F "usebackq tokens=*" %%F in (`dir /a-d /b /s %%D ^| findstr ".c .cc"`) do (
    echo #include "%%F"
  )
)
