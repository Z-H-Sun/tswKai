# tswKai
Tower of the Sorcerer for Windows Kai (改): Modifier of game variables and improvement of game experience / 魔塔英文原版修改器 及 汉化、提升游戏体验补丁

See Also / 另请参见: [tswMovePoint（座標移動）](https://github.com/Z-H-Sun/tswMP); [tswSaveLoad（临时存档）](https://github.com/Z-H-Sun/tswSL)

![Preview of tswKai](/2.png)|![汉化](/1.png)
---|---

## Scope of application / 适用范围
This mod can only be applied to TSW English Ver 1.2. You can download its installer <ins>[here](https://ftp.vector.co.jp/14/65/3171/tsw12.exe)</ins> or visit [the official website](http://hp.vector.co.jp/authors/VA013374/game/egame0.html). You will have to run the executable **as administrator** to install. / 本修改器仅适用于英文原版魔塔V1.2，可于<ins>[此处](https://ftp.vector.co.jp/14/65/3171/tsw12.exe)</ins>下载其安装包，或[点此](http://hp.vector.co.jp/authors/VA013374/game/egame0.html)访问官网。必须右键**以管理员权限运行**才可成功安装。

#### Game experience improvement / 提升游戏体验
* I modified the original TSW program to improve game experience by a little bit. Previously, the refresh rate was too low, so I increased it to make the game run smoother (150 ms → 75 ms for high speed, 250 ms → 150 ms for normal speed, and 350 ms → 250 ms for low speed); the white text on gray background could hardly be read, so I changed the text color. In addition, a Chinese translated version was also included. You can opt to download <ins>[this patch archive file](https://github.com/Z-H-Sun/tswKai/raw/main/tsw.patch.zip)</ins>, and extract all contents in the installation folder of TSW (for example, `C:\Program Files (x86)\Tower of the Sorcerer`). Run `TSW.EN.exe` (English) or `TSW.CN.exe` (Chinese) instead of `TSW.exe`. / 为提升游戏体验，可选择使用补丁：原先魔塔程序刷新速率太低，导致很卡，目前将原先的高速、中速、低速分别由150、250、350毫秒的刷新间隔缩短至75、150、250毫秒；原先对话框灰底白字看不清楚，因此修改了字色；此外，还添加了汉化版。使用方法：将<ins>[此补丁压缩包](https://github.com/Z-H-Sun/tswKai/raw/main/tsw.patch.zip)</ins>解压至安装目录下（例如`C:\Program Files (x86)\Tower of the Sorcerer`），并运行`TSW.EN.exe`（英文版）或`TSW.CN.exe`（汉化版）。
* An Excel spreadsheet was made to facilitate calculation of battle loss since the “orb of hero” cannot provide some important information. For example, the effect of cross and dragon slayer is taken into consideration; the details of battle are quantified to formulate better strategy; the macro has been used to directly link with the game process without the need for manual input of data. Download <ins>[the Excel file](https://github.com/Z-H-Sun/tswKai/raw/main/tsw.xlsm)</ins>, enable the macro, run TSW, click the `Link2TSW` button, and throw away your calculator! / 游戏中的“英雄之杖（怪物手册）”提供的信息过少，可选择使用<ins>[此 Excel 电子表格](https://github.com/Z-H-Sun/tswKai/raw/main/tsw.xlsm)</ins>来减少游戏计算量。该文档考虑了十字架和屠龙匕的作用（怪物手册没有）；显示了战斗伤害的细节（回合伤害、回合数、临界值）以方便制定加攻防策略；使用宏与游戏进程直接连接从而无需手动输入游戏数据。下载后，启用宏，打开魔塔，点击`Link2TSW`按钮，再也不用手按计算器了！
![Damage calculator](/3.png)

## Which to download / 下载链接
* For Windows 7 / XP Users, please download <ins>[the basic version](https://github.com/Z-H-Sun/tswKai/releases/latest/download/tswKaiBasic.exe)</ins> which is compatible with the old OS. / Win 7或XP用户请下载适配旧操作系统的<ins>[基本版](https://github.com/Z-H-Sun/tswKai/releases/latest/download/tswKaiBasic.exe)</ins>。
* For Windows 10 Users, please download <ins>[the full version](https://github.com/Z-H-Sun/tswKai/releases/latest/download/tswKai.exe)</ins> which is optimized for the latest console features. **However, if you use the legacy console mode** ([What's this?](https://go.microsoft.com/fwlink/?LinkId=871150)), please fall back on the basic version. / Win 10用户请下载为新版控制台特性而优化的<ins>[完整版](https://github.com/Z-H-Sun/tswKai/releases/latest/download/tswKai.exe)</ins>；但如果使用了旧版控制台模式（[了解更多](https://go.microsoft.com/fwlink/?LinkId=871150)）**导致显示不正确**，请回退至基本版。
* It is just one single executable; double click to run. / 下载后仅单个可执行文件，双击运行即可。

## Usage / 使用方法
* Open tswKai followed by TSW. Otherwise, you need to manually input the PID of the TSW process. / 先开魔塔再开修改器，否则需要手动输入游戏进程PID。
* A list of variables and their values will be shown: HP, ATK, DEF, gold, the current floor, the highest floor you've been to (which affects the orb of flying), the current X and Y coordinates (from top/left to bottom/right: 0, 1, 2, ..., 8, 9, 10/A), the number of three keys, the current weapons (sword and shield; 0 = none, 1 = iron, 2 = silver, 3 = knight, 4 = holy, 5 = sacred), and the number of other items (shown in the same order as that in the sidebar in the game). / 界面将显示变量列表及对应值：血攻防金、楼层、所达最高楼层（影响楼层传送器）、当前坐标（自左上向右下编号，记为0, 1, 2, …, 8, 9, 10或A）、三种钥匙数量、剑盾（0-无，1-铁，2-银，3-骑士，4-圣，5-神圣）、其他各道具数量（按侧边栏顺序排列）。
* Each variable is denoted as a single letter or number (labeled in brackets or in yellow). Press the corresponding key to select that variable, or press <kbd>Z</kbd> to simply refresh the list. / 各变量用单个字母或数字表示（已标黄或括起来），按下对应按键以选择该变量。若按<kbd>Z</kbd>键则刷新此列表。
* Follow the instructions to input the desired new value. Note the upper and lower limits. And then press <kbd>Enter</kbd> to continue. 根据提示输入想要的新数值，请注意上限及下限。随后按<kbd>Enter</kbd>继续。
* At any time, press <kbd><kbd>Ctrl</kbd>+<kbd>C</kbd></kbd> to abort the current operation. / 无论何时可按下<kbd><kbd>Ctrl</kbd>+<kbd>C</kbd></kbd>中止当前操作。
* **IMPORTANT**: Although the change of value of the variable will take effect immediately, the game process itself will not refresh until next relevant event takes place, e.g. battle, obtaining or using an item, etc. / **重要**：尽管变量值的更改会立即生效，但游戏进程内部并不会实时刷新；只有当下次触发“相关事件”后（如战斗、得到或用掉某件道具等）才会刷新。
