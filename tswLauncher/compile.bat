@echo off
IF "%CC%" == "" SET CC=gcc
echo You will be using "%CC%" as C compiler, whose version info is printed out below.
"%CC%" -dumpmachine
"%CC%" --version
echo.
echo Please check if it compiles 32-bit executables; otherwise, the compiled tswLauncher will not work if there has been a previous installation of TSW on Windows Vista or later!
echo Refer to the 'VirtualStore' related paragraphs in the link below
echo https://learn.microsoft.com/en-us/previous-versions/technet-magazine/cc138019(v=msdn.10)
echo.
pause
@echo on

windres res.rc res.o && "%CC%" -s -g0 -DNDEBUG -Os -Wall -mwindows -o tswLauncher.exe gui.c tswLauncher.c res.o -lgdi32 -lshlwapi
@echo off
echo.
pause
