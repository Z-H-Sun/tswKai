@echo off

REM Add path
IF defined CDIR set "PATH=%CDIR%;%PATH%"

REM C compiler
IF defined CC (
  set "CCPATH=%CC%"
  REM Add extension name if absent
  FOR /F "delims=" %%I IN ("%CC%") DO (
    IF "%%~xI" == "" set "CCPATH=%CC%.exe"
  )
  REM Default C compiler
) ELSE set CCPATH=gcc.exe
IF exist "%CCPATH%" (
  REM Expand to its full path if %CCPATH% exists under the current path
  FOR /F "delims=" %%I IN ("%CCPATH%") DO set "CCPATH=%%~fI"
) ELSE (
  REM Find it under $PATH
  FOR /F "delims=" %%I IN ("%CCPATH%") DO set "CCPATH=%%~$PATH:I"
  IF NOT defined CCPATH (
    echo No C compiler found.
    goto END
  )
)

REM Check dependencies
FOR %%I IN (CPP WINDMC WINDRES) DO (
  set FOUNDPATH=
  IF exist "%%I.exe" (
    FOR /F "delims=" %%J IN ("%%I.exe") DO set "FOUNDPATH=1" & set "%%IPATH=%%~fJ"
  ) ELSE (
    FOR /F "delims=" %%J IN ("%%I.exe") DO set "FOUNDPATH=1" & set "%%IPATH=%%~$PATH:J"
    IF NOT defined FOUNDPATH (
      echo No %%I found.
      goto END
    )
  )
)

echo.
echo You will be using the following C compiler:
echo CC="%CCPATH%"
echo.
echo whose version info is printed out below:
"%CCPATH%" -dumpmachine
"%CCPATH%" --version
echo ----------
echo Please check if it compiles 32-bit executables; otherwise, the compiled tswLauncher will not work if there has been a previous installation of TSW on Windows Vista or later!
echo For more info, refer to the 'VirtualStore' related paragraphs in the link below:
echo https://learn.microsoft.com/en-us/previous-versions/technet-magazine/cc138019(v=msdn.10)
echo ----------
echo.
echo You will also be using:
echo CPP="%CPPPATH%"
echo WINDMC="%WINDMCPATH%"
echo WINDRES="%WINDRESPATH%"
echo ----------
echo Please make sure they are compatible with the C compiler above, i.e., they generate 32-bit output files.
echo.
pause

@echo on
cpp -P -fno-extended-identifiers -x assembler-with-cpp msg.mcp msg.mc && windmc -C 65001 -O 65001 -U -F pe-i386 -e hc -n msg.mc && windres res.rc res.o && "%CCPATH%" -std=gnu99 -s -g0 -DNDEBUG -Os -Wall -mwindows -o tswLauncher.exe gui.c font.c LE.c patch.c tswLauncher.c res.o -lgdi32 -lcomdlg32 -lshlwapi -lgdiplus
@echo off
echo.

:END
set CCPATH=
set CPPPATH=
set WINDMCPATH=
set WINDRESPATH=
set FOUNDPATH=
pause
