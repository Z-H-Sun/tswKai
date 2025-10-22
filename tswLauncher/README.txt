tswLauncher

... Configures the installation of TSW and runs a specified subtype of TSW.

tswLauncher.exe should be placed in a folder with a subfolder called `TSW1.2r3`, which is the path of a portable TSW package. The TSW package, which contains the executables for the four subtypes below, can be found in the all-in-one release in this link: https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip

* English (Original): TSW.exe
* English (Retranslated): TSW.EN.exe
* Chinese: TSW.CN.exe
* Chinese (Retranslated): TSW.CNJP.exe

For the detailed introduction of the four subtypes and the usage of tswLauncher, see: https://github.com/Z-H-Sun/tswKai/wiki/1.1-%E2%80%90-Run-TSW-Game

Only one instance of tswLauncher or TSW can be running at a time. If a specified subtype of TSW starts successfully, its window will be repositioned in the center of the screen (instead of the top left corner); if it fails to start, the process will be terminated within 4 seconds. If the current system locale setting is incompatible with the subtype of TSW selected, and if the `LE` (LocaleEmulator) plugin is present and functional (which requires Windows 7 Service Pack 1 or higher), you can choose to emulate a compatible locale for this TSW process to solve the mojibake issue.

TSW records the data storage path and program installation path in the following config file: %windir%/TSW12.INI
For Windows Vista or later systems with user access control (UAC) enabled, the path is instead %localappdata%/VirtualStore/Windows/TSW12.INI

If you have previous installation of TSW, tswLauncher will do the following:
- If a valid TSW12.BAK.INI exists: will use the old data-save path in that file and the current installation path; will overwrite the TSW12.INI file and ignore the configs therein
- ElseIf a valid TSW12.INI exists: will use the old data-save path in that file and the current installation path; will overwrite the TSW12.INI file, and only when its old installation path differs from the current one, will make a backup copy of it as TSW12.BAK.INI
- Else : will use the current data-save path and the current installation path

In addition,
- If the old data-save path is a subfolder of the old installation path, it is recommended to perform migration, and a messagebox will pop up on startup
- If the old data-save path is not the default path (./TSW1.2r3/Savedat), the Migration button will be enabled; otherwise, the button will be disabled
- The Migration function will copy all files under the old data-save path to the current, default path (./TSW1.2r3/Savedat); remove TSW12.ini and TSW12.BAK.INI if present; and write a new TSW12.ini with the current installation and data-save paths

Using the Config button, you can enable/disable patches and adjust game timers, etc., for the specified subtype of TSW. You can also perform this task for a custom TSW executable file, by clicking the '...' button or drap-and-drop a file to the dialog.

In order to compile tswLauncher, you must use a 32-bit C compiler, and `set CC=<that_compiler>` (if its name is not `gcc`) and `set CDIR=<path_to_CC>` (the path to the compiler toolchain, including `gcc`, `cpp`, `windmc`, and `windres`); then run `compile.bat` in this folder.
