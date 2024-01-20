tswLauncher

... Configures the installation of TSW and runs a specified subtype of TSW.

tswLauncher.exe should be placed in a folder with a subfolder called `TSW1.2r1`, which is the path of a portable TSW package. The TSW package, which contains the executables for the four subtypes below, can be found in the all-in-one release in this link: https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip

* English (Original): TSW.exe
* English (Revised): TSW.EN.exe
* Chinese: TSW.CN.exe
* Chinese (Retranslated): TSW.CNJP.exe

For the detailed introduction of the four subtypes and the usage of tswLauncher, see: https://github.com/Z-H-Sun/tswKai/wiki/1.1-%E2%80%90-Run-TSW-Game

Only one instance of tswLauncher or TSW can be running at a time. If a specified subtype of TSW starts successfully, its window will be repositioned in the center of the screen (instead of the top left corner); if it fails to start, the process will be terminated within 4 seconds.

TSW records the data storage path and program installation path in the following config file: %windir%\TSW12.INI 
For Windows Vista or later systems with user access control (UAC) enabled, the path is instead %localappdata%\VirtualStore\Windows\TSW12.INI 

If you have previous installation of TSW, tswLauncher will do the following:
- If a valid TSW12.BAK.INI exists: will use the old data-save path in that file and the current installation path; will overwrite the TSW12.INI file and ignore the configs therein
- ElseIf a valid TSW12.INI exists: will use the old data-save path in that file and the current installation path; will overwrite the TSW12.INI file, and only when its old installation path differs from the current one, will make a backup copy of it as TSW12.BAK.INI
- Else : will use the current data-save path and the current installation path

In order to compile tswLauncher, you must use a 32-bit C compiler, and `set CC=<that_compiler>` (if its name is not `gcc`); then run `compile.bat` in this folder.
