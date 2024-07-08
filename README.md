# tswKai3 [![GitHub Repo](https://img.shields.io/badge/%E2%80%8B-GitHub-informational?logo=GitHub&style=plastic)](https://github.com/Z-H-Sun/tswKai) [![Wiki Page](https://img.shields.io/badge/%E2%80%8B-Wiki-important?logo=Wikipedia&style=plastic)](https://github.com/Z-H-Sun/tswKai/wiki) [![License](https://img.shields.io/badge/%E2%80%8B-MIT-brightgreen?logo=Coursera&style=plastic)](LICENSE)
Tower of the Sorcerer for Windows Kai (改): Modifier of game variables and improvement of gaming experience

魔塔英文原版 TSW 修改器 及 汉化、提升游戏体验补丁

***New Release v3.1.5: Please visit [the release page](https://github.com/Z-H-Sun/tswKai/releases/tag/v3.1.5) for details on new features!***<br>
***新版本 v3.1.5：请前往 [发布页面](https://github.com/Z-H-Sun/tswKai/releases/tag/v3.1.5) 查看新版本特性！***

> See Also / 另请参见: [PC98TSKai（PC98 原版魔塔-改）](https://github.com/Z-H-Sun/PC98TSKai)［Coming soon! / 开发中，即将上线］

> [!important]
> This README is just a brief summary of the basic functions and usage of the software. For more details and troubleshooting, please see its full documentation in the <ins>[Wiki](https://github.com/Z-H-Sun/tswKai/wiki)</ins> page, which is also availabe in the release.
>
> 本 使用必读 仅作基本功能和用法的简述，若想查看更多细节以及疑难解答，请参见完整文档：其 本地版本 可以在软件的发行版中找到；在线版本 请参考 <ins>[百科页面](https://github.com/Z-H-Sun/tswKai/wiki)</ins>。

> [!note]
> If you are an old user of the legacy [`tswKai`](https://github.com/Z-H-Sun/tswKai/tree/legacy_v2) (v2), please note that this brand-new `tswKai3` is completely different from its predecessor and has integrated the functions in [`tswMovePoint`](https://github.com/Z-H-Sun/tswMP/tree/v3.0), [`tswSaveLoad`](https://github.com/Z-H-Sun/tswSL/tree/v2.023), and [`tswBGM`](https://github.com/Z-H-Sun/tswBGM/tree/v2.0.2.3) projects, as well as other substantial updates.
>
> 如果你是之前的旧版 [`tswKai`](https://github.com/Z-H-Sun/tswKai/tree/legacy_v2) (v2) 用户，请注意本次大版本更新后的 `tswKai3` 与其先代完全不同，不仅融合了 [`tswMP（座標移動）`](https://github.com/Z-H-Sun/tswMP/tree/v3.0)、[`tswSL（临时存档）`](https://github.com/Z-H-Sun/tswSL/tree/v2.023)、[`tswBGM（背景音乐）`](https://github.com/Z-H-Sun/tswBGM/tree/v2.0.2.3) 等其他项目的所有功能，还进行了史诗级的更新。

|![Sample Image 1](https://github.com/Z-H-Sun/tswKai/wiki/img/1.2.2-1.png)|![Sample Image 2](https://github.com/Z-H-Sun/tswKai/wiki/img/c1.2.5-1.png)|
|---|---|

## Download / 下载

You will need a Windows OS to run this software. ***Windows XP and later (up to Windows 11)*** platforms are recommended. The software is not guaranteed to run properly on earlier versions of Windows or on an emulator. *No other system requirements are needed.*

本软件的运行平台为 Windows，推荐使用 ***Windows XP 及以上（含 Windows 11）*** 版本。无法保证在更低 Windows 版本或模拟器上能正常运行。*无其他系统需求。*

It is recommended to download the latest <ins>[all-in-one package](https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip)</ins>. Extract its contents into any path you like (*preferably a permanent path*), and no need to install. It will take up ~35 MB space.

推荐下载最新版的 <ins>[软件整合包](https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip)</ins>。功能俱全，绿色无需安装（约 35 MB），解压到任意路径即可（*最好是一个不会变动的永久路径*）。

> [!tip]
> The package also includes this README and all Wiki pages. For Chinese, please open `使用必读.html`; for English, please open `README.html`. Chrome / Edge is recommended for browsing the files.
> 
> 此整合包中已包含本 README 和所有 百科页面。中文：请打开其中的 `使用必读.html`；英文：请打开其中的 `README.html`。推荐使用 Chrome / Edge 浏览器打开。

## Features / 特性

For the TSW program itself: / 针对魔塔游戏本体：

* Corrected translation based on the original Japanese version<br/>
根据日语原版校正翻译、汉化

* Raised the refresh rate and solved lag<br/>
提高刷新率，解决卡顿

* Improved keyboard control of player movement by shortening the delay when holding down an arrow key<br/>
  大幅改进键盘控制玩家移动的手感，减弱长按方向键后第一下的停顿感

* Improved movement / stair / door-opening / battle animations, which are made much smoothier<br/>
  大幅改进移动、上下楼、开门、战斗等动画，使其变得十分丝滑

* Fixed a bug on the display of GOLD income for defeating "strike-first" monsters<br/>
  修正先攻怪显示奖励金币数的 bug

* Changed the text colors so as to make them clearer against the gray background<br/>
解决对话框底色字色衬度低看不清的问题

* Added shortcut keys for saving/loading files, toggling background music on/off, and game speed modes<br/>
增加存档、读档、开关背景音乐、设置游戏速度等快捷键

* Added a "Super High Speed" mode, significantly reducing the refresh interval and animation duration in the game, which is well suitable for experienced players who would like to focus on calculations and route optimization<br/>
增加 “极速模式”，大幅缩短刷新间隔和动画时长，适用于专注计算和路线优化的老玩家

* Fixed bugs including text misplacement, tile mask offset, heap overflow, etc. (For details, please see [Corrections Log](https://github.com/Z-H-Sun/tswKai/wiki/1.1-‐-Run-TSW-Game#corrections-log))<br/>
修复包括文本串行、蒙版错误、堆溢出等一众 bug（详见 [修正事项](https://github.com/Z-H-Sun/tswKai/wiki/§1.1-‐-运行魔塔游戏#修正事项)）

> [!note]
> The English Version TSW and its Flash replica (derived from the English Version TSW while including some modifications from the author) differ significantly from the original Japanese Version TSW in terms of dialog terminology and item nomenclature.
> * Therefore, the release includes a "normal" Chinese translated version, where the terminology and dialog translations have been adjusted to accommodate naming conventions used in both the English / Japanese Version TSW and the Flash replica. This ensures accurate conveyance of the author's intentions while avoiding alienation for veteran players.
> * In contrast, the "retranslated" Chinese version and "revised" English version, also included in the release, adhere more closely to the original meaning of the dialogs in the Japanese Version TSW in order to provide players with an authentic experience of a Japanese RPG.
>
> 英语版 TSW 及早先的 Flash 移植版（由英语版 TSW 二次翻译出发，并加入了作者自己的一些改动）与日语原版的一些台词颇有出入。
> * 因此，发行版中加入了一个“普通汉化版”魔塔，其中的用语译名和对话翻译针对英文原版、日文原版以及 Flash 移植版的命名方式进行了一定的调和，在准确传达原作者本身的意图之余，也不至于让老玩家产生距离感。
> * 而发行版中另附的“日文精译版”和“英语（修正）版”在此基础上，更靠近日文原版的台词原义，让玩家能更原汁原味地纯享日文 RPG 的风味。

<details><summary>To avoid confusion, click here to expand the table where a comparison is drawn between the terminologies used in English (Revised) / Chinese (Retranslated) subtypes and old translations:<br/>为了消除误解，点此展开以列出部分 <code>英语修正版</code> / <code>日文精译版</code> 的用语和旧译之间的对照：</summary>
<p></p>

| 新译法 | 旧译法 | New Terms | Old Terms | 日本語 |
| --- | --- | --- | --- | --- |
|门（无定语修饰）|黄门|-|Door (no adjective)|扉|
|紫门|蓝门|-|Blue Door|紫色の扉|
|闸门|机关门（逻辑门）|-|Gate|門|
|钥匙（无定语修饰）|黄钥匙|-|Key (no adjective)|鍵|
|紫钥匙|蓝钥匙|-|Blue Key|紫色の鍵|
|生命力|生命值|HP|Vital Power|生命力|
|-|攻击力|ATK|Offensive Power|攻撃力|
|-|防御力|DEF|Defensive Power|防御力|
|祭坛|商店|-|Altar|祭壇|
|蓝/红回复药|大/小血瓶|Blue/Red Elixir|Blue/Red Potion|青い/赤い回復薬|
|蓝/红水晶|蓝/红宝石|-|Blue/Red Crystal|青/赤のクリスタル|
|神盾|神圣盾|-|Sacred Shield|神盾|
|神剑·威珀讷『Weaponer』|神圣剑|-|Sacred Sword "Weaponer"|神剣ウェポナー|
|全知神杖·殷忒镠『Intellion』|智慧权杖|-|Omniscient Staff "Intellion"|全能の杖インテリオン|
|勇者灵球|怪物手册|Orb of Hero|Orb of the Hero|勇者のオーブ|
|智慧灵球|备忘录|-|Orb of Wisdom|知恵のオーブ|
|飞翔灵球|楼层传送器|Orb of Flight|Orb of Flying|飛翔のオーブ|
|万灵药|圣水|Elixir|Magic Elixir|エリクサー|
|破坏爆弹|炸弹|Destruction Ball|Destrubtible Ball|破壊の玉|
|空间转移秘宝（瞬移之翼）|中心对称飞行器|Warp Wing|Warp Staff|空間転移の秘宝|
|升华之翼|上楼器|Ascent Wing|Wing to Fly Up|昇華の翼|
|降临之翼|下楼器|Descent Wing|Wing to Fly Down|降臨の翼|
|雪之结晶|冰魔法（冰冻徽章）|-|Snow Crystal|雪の結晶|
|超级镐（宝石魔镐）|地震卷轴|Super Mattock|Super Magic Mattock|スーパーマトック|
|盗贼|小偷|-|Thief|盗賊|
|蝙蝠|小蝙蝠|-|Bat|バット|
|僧侣（祭司）|初级法师|-|Priest|僧侶|
|上级僧侣（大祭司）|高级法师|High Priest|Superion Priest|上級僧侶
|门卫·甲/乙/丙|高/中/初级卫兵|Gateman A/B/C|Gate-Keeper A/B/C|門番Ａ/Ｂ/Ｃ|
|骷髅·甲/乙/丙|骷髅队长/骷髅士兵/骷髅人|-|Skeleton A/B/C|スケルトンＡ/Ｂ/Ｃ|
|丧尸（骑士）|兽人（武士）|-|Zombie (Knight)|ゾンビ（ナイト）
|石怪|石头人|-|Rock|ロック|
|史莱姆·绿/红/大|绿色/红色/大史莱姆|Slime G/R/B|Green/Red/Big Slime|Ｇ/Ｒ/Ｂスライム|
|史莱姆人|幽灵|-|Slime Man|スライムマン|
|-|史莱姆王|Slime K|Slime Lord|Ｋスライム|
|龙|魔龙|-|Dragon|ドラゴン|
|死灵战士|鬼战士|-|Ghost Soldier|死霊兵士|
|剑士|双手剑士|-|Swordsman|剣士|
|金骑士|骑士队长|-|Golden Knight|金騎士|
|黑骑士|黑暗骑士|-|Dark Knight|黒騎士|
|魔术士·甲/乙（高/级术士）|高/初级巫师|-|Magician A/B|魔術士Ａ/Ｂ|
|魔导师|魔法警卫|Sorcerer|Magic Sergeant|魔導師|
|大魔导师|大法师|Archsorcerer|Great Magic Master|大魔導師|
|魔导师·芝诺|魔王zeno|Zeno the Sorcerer|Magic Sergeant, Zeno|魔導師ゼノ|

The differences in dialog lines are not shown here due to space limitations.<br/>
对话台词的区别囿于篇幅不作展示。

</details>

---

For the tswKai3 mod: / 针对魔塔修改器：

* Support both English and Chinese display languages; can be put into hibernation while waiting for the next TSW process to start<br/>
同时支持中/英文显示语言；支持休眠等待下一次魔塔游戏启动

* Can choose which patches / enhancements to apply, with two options: One *takes effect only during runtime* and the other *makes permanent changes*<br/>
可以选择性地设置要修正哪些 bug、添加哪些增强功能，且提供了 *仅运行时修正* 和 *永久修正* 两种选项

  *For its usage,see [Patch Config](#patch-config--修正设置) (For details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.1-‐-Patch-Config))<br/>具体用法请参见 [修正设置](#patch-config--修正设置)（详见其对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.1-‐-修正设置)）*

* Can use mouse to teleport in the current map (i.e., fast-move to a new destination; the connectivity of the destination with respect to the starting location will be checked); can use shortcut keys to use items; can display on-map damage for each monster; can show monster details (with analyses of ATK-critical-values and battle round counts) and 44 analyses in the back-side tower (i.e., display the real properties after divided by 44 (*or other custom multiplication factor specified in [the cheat console](https://github.com/Z-H-Sun/tswKai/wiki/1.2.5-‐-Cheat-Console#usage)*))<br/>
支持使用鼠标点选（快速移动到地图上的新位置，会判断当前位置和目的地之间的连通性）、宝物快捷使用（按快捷键直接使用道具）、地图显伤（显示怪物伤害）、怪物详情（攻击临界和回合数等分析）、里侧塔 44 分析（显示除以 44（*或者其他由 [作弊控制台](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.5-‐-作弊控制台#用法) 指定的自定义倍数*）以后的实际属性值）

  *For its usage,see [Map Enhancement](#map-enhancement--地图增强) (For details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.2-‐-Map-Enhancement))<br/>具体用法请参见 [地图增强](#map-enhancement--地图增强)（详见其对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.2-‐-地图增强)）*

* Can auto-save snapshots so as to take back a move; can save to / load from data of arbitrary file names<br/>
支持自动存档从而实现撤销功能（类似于 HTML5 魔塔的 <kbd>A</kbd> 键功能）、支持读取/保存任意名称的存档

  *For its usage,see [Save/Load Data](#saveload-data--存档相关) (For details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.3-‐-Save／Load-Data))<br/>具体用法请参见 [存档相关](#saveload-data--存档相关)（详见其对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.3-‐-存档相关)）*

* Enhanced background music with fade-in/out effects and no more lag; corrected the timing of BGM playback; added one piece of music for the 44-th floor; etc.<br/>
支持背景音乐增强功能，不再卡顿，有淡入淡出，修正触发播放 BGM 的时机，新增 44 层音乐 等等

  *For its usage,see [Background Music](#background-music--背景音乐) (For details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.4-‐-Background-Music))<br/>具体用法请参见 [背景音乐](#background-music--背景音乐)（详见其对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.4-‐-背景音乐)）*

* Can use the cheat console to change the game variables (the map display will be auto updated afterwards)<br/>
可以进入作弊器界面修改游戏变量（含地图自动刷新）

  *For its usage,see [Cheat Console](#cheat-console--作弊控制台) (For details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.5-‐-Cheat-Console))<br/>具体用法请参见 [作弊控制台](#cheat-console--作弊控制台)（详见其对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.5-‐-作弊控制台)）*

> [!note]
> Screenshots for either English or Chinese version are shown below by random. For the other language version not shown here, please see the corresponding Wiki.
>
> 以下将随机显示中文版或英文版的截图。若想查看未显示的中文版的截图，请参见相关的 百科页面。

## Usage / 使用方法

> [!tip]
> The default display language (English/Chinese) for the TSW launcher and mod is determined by the user's language settings at first. Later, when the TSW game starts running, the mod's display language will be changed to TSW's language. The mod's language can also be configured according to the [Advanced Options](#advanced-options--高级设置) section.
>
> 魔塔启动器和修改器的默认显示语言（英文/中文）一开始由系统的用户语言设置决定。若魔塔游戏正在运行中，则修改器的显示语言改由运行中的魔塔版本决定。修改器的语言设定也可通过 [高级设置](#advanced-options--高级设置) 配置。

### Run TSW Game / 运行魔塔游戏
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.1-‐-Run-TSW-Game) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.1-‐-运行魔塔游戏)*

* Run `tswLauncher.exe` (see the left figure below).<br/>
运行 `tswLauncher.exe`（见左下图）。

* Use mouse or arrow key to select a subtype in the dropdown list, and then press <kbd>Enter</kbd> key or click on the `Launch` button to run TSW.<br/>
用鼠标或方向键从列表中选定想要运行的魔塔类型，然后按 <kbd>回车</kbd> 键或单击 `运行` 按钮启动。

  * `English (Original)`: Most similar to the original version; the translation is not corrected<br/>
  `英语（原版）`：最贴近原版；翻译未校正

  * `English (Revised)`: Most of inappropriate translations are corrected with reference to the Japanese version<br/>
  `英语（修正版）`：参照日语版校正了大部分不恰当的翻译

  * `Chinese`: Translations are adjusted to accommodate naming conventions used in both the English / Japanese Version TSW and the Flash replica.<br/>
  `汉化`：译名采取 Flash 版、英语版和日语版 TSW 之间的折中译法

  * `Chinese (Retranslated)`: Terms are retranslated with reference to the Japanese version<br/>
  `汉化（日语精译版）`：译名采取了更为贴近日语版的译法

|![tswLauncher](https://github.com/Z-H-Sun/tswKai/wiki/img/1.1-1.png)|![tswKai3 Status Window](https://github.com/Z-H-Sun/tswKai/wiki/img/c1.2-1.png)|
|---|---|

> [!tip]
> For experienced players who would like to focus on calculations and route optimization: You may want to skip the "prologue" animation on game startup and reduce the refresh interval and animation duration in the game. If so, please untick the `Options -> Prologue` menu item, select the `Options -> Speed -> Super High` menu item, and finally click `Options -> Save Options`.
>
> 对于专注计算和路线优化的老玩家而言，可能希望跳过游戏开头的 “序章” 动画并尽可能缩短游戏的刷新间隔和动画时长，此时可以取消选中 `设置 -> 序章` 菜单，选择 `设置 -> 速度 -> 极速` 菜单，最后再点 `设置 -> 保存选项`。

---

### Run tswKai3 / 运行修改器
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2-‐-Run-tswKai3) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2-‐-运行修改器)*

* Run `tswKai3.exe`.<br/>
运行 `tswKai3.exe`。

* If TSW is not running, a status window (as shown in the right figure above) will be displayed in the top left corner of the screen.<br/>
若魔塔游戏未运行，将在屏幕左上角显示如右上图所示的状态窗口。

* After TSW has started, the Config window will pop up first (see next section), followed by a message box summarizing the basic usage of this app (see left figure below).<br/>
运行魔塔游戏后，将首先弹出 设置 窗口（见下节），随后会如左下图所示，简介本修改器的基本用法。

* After TSW has quitted, a message box will pop up and ask if you want to standby and wait for the next TSW game to start.<br/>
当魔塔游戏退出后，将弹窗询问是否待机等待下一次魔塔游戏启动。

* At any time, press <kbd>F7</kbd> to bring the TSW window to foreground; press and hold the <kbd>F7</kbd> key to exit this mod app.<br/>
随时可以按 <kbd>F7</kbd> 键将魔塔游戏唤至前台；长按 <kbd>F7</kbd> 键退出本修改器程序。

*  If you come across an error window like shown in the right picture below and cannot solve the problem according to the message prompts, please [submit an issue](https://github.com/Z-H-Sun/tswKai/issues/new), including the following information: `tswKai3` version number; steps to reproduce the error; and the error type, message, and traceback information shown in the error window.<br/>
如果遇到如右下图所示的错误弹窗，且按照消息提示无法解决问题，请 [提交 Issue](https://github.com/Z-H-Sun/tswKai/issues/new)，其中务必包含以下信息：`tswKai3` 版本、错误复现条件、弹窗中显示的错误类别、消息、追溯。

|![tswKai3 Welcome Screen](https://github.com/Z-H-Sun/tswKai/wiki/img/c1.2-2.png)|![tswKai3 Error Dialog](https://github.com/Z-H-Sun/tswKai/wiki/img/1.2-3.png)|
|---|---|

---

### Patch Config / 修正设置
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.1-‐-Patch-Config) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.1-‐-修正设置)*

|Scheme / 方案|Advantages / 优点| Disadvantages / 缺点|
|:---:|---|---|
|Dynamic (Runtime)<br/>动态 (运行时)|Can change the settings in the Config window anytime during the TSW game<br/>可在魔塔游戏过程中随时前往 设置 对话框更改设置|Will only take effect when this modifier app is running<br/>只有启动本修改器程序后才会生效|
|Static (Permanent)<br/>静态 (永久)|Once the patches are written into the executable, they will take effect even without the mod running<br/>一旦写入可执行文件，无需启动修改器也可生效|Changing settings will still have to involve using this modifier app<br/>若要更改设置，仍需借助本修改器|

* *Dynamic Patch* (as shown in the left figure below):<br/>
*动态修正*（如左下图所示）：

  * When tswKai3 detects the start of the TSW game process, it will, by default, display the "Config (Dynamic)" dialog box first and ***automatically apply*** the items shown in the left figure below;<br/>
  当 tswKai3 检测到魔塔游戏进程启动时，会默认首先显示 “设置（动态）” 对话框，并会默认 ***自动应用*** 如左下图中所示的项目；

  * During the game later on, you can press <kbd>F8</kbd> at any time to show this "Config (Dynamic)" dialog box again.<br/>
  随后在游戏中途，随时可按 <kbd>F8</kbd> 调出此 “设置（动态）” 对话框。

* *Static Patch* (as shown in the right figure below)<br/>
*静态修正*（如右下图所示）：

  * Drag the TSW executable file to be modified (*make sure it is not running*) onto `tswKai3.exe`, and a "Config (Static)" dialog box will appear;<br/>
  将欲修正的魔塔可执行文件（*请确保其未在运行中*）拖拽至 `tswKai3.exe` 上，将显示 “设置（静态）” 对话框；

  * <details><summary>Click here for the relevant executables' filenames<br/>点此查看相关可执行文件的文件名</summary>

    <p></p>

    If you are using [the all-in-one package](https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip), these files are located in the `TSW1.2r1` subfolder:<br/>
    如果使用的是 [软件整合包](https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip)，则可在 `TSW1.2r1` 子文件夹中找到它们：

    `TSW.exe` - English (Original) / 英语（原版）<br/>
    `TSW.EN.exe` - English (Revised) / 英语（修正版）<br/>
    `TSW.CN.exe` - Chinese / 汉化<br/>
    `TSW.CNJP.exe` - Chinese (Retranslated) / 汉化（日语精译版）

    </details>

* In the Config dialog, you can use the mouse or keyboard to tick/untick the items. After setting an item, the input focus will automatically move to the next item.<br/>
在设置对话框中，可使用鼠标或键盘选中/取消选中对应的项目；设置完某条项目后焦点将自动转移至下一条目。

  * Please refer to the [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.1-‐-Patch-Config) for each item's specific function;<br/>
  每条项目的具体功能请参见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.1-‐-修正设置)；

  * ***The settings will be automatically saved***. After finishing the settings, simply click on the X button of the window or press <kbd>Enter</kbd>/<kbd>ESC</kbd> key.<br/>
  ***设置将自动保存***。设置结束后，按右上角 × 按钮或按 <kbd>回车</kbd> / <kbd>ESC</kbd> 键结束即可。

|![Dynamic Patch](https://github.com/Z-H-Sun/tswKai/wiki/img/c1.2.1-1.png)|![Static Patch](https://github.com/Z-H-Sun/tswKai/wiki/img/1.2.1-2.png)|
|---|---|

---

### Map Enhancement / 地图增强
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.2-‐-Map-Enhancement) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.2-‐-地图增强)*

Hold <kbd>Tab</kbd> or the left <kbd>⊞ WIN</kbd> hotkey to use the ***Mouse Fast-Move***, ***Item Shortcut-Keys***, and ***On-Map Damage*** functions. You will see a banner above the bottom status bar, and please follow the prompts there (see the figures below).<br/>
长按 <kbd>Tab</kbd> 或 左侧 <kbd>⊞ WIN</kbd> 快捷键以使用 ***鼠标点选***、***宝物调用***、***地图显伤*** 功能。此时将在底部状态栏上方显示一个横幅，请参照其中的提示文本操作（如下图所示）。

* ***Mouse Fast-Move***: Move the mouse around in the game map to pick a destination<br/>
***鼠标点选***：移动鼠标在游戏地图内选定位置，

  * ${\textsf{\color{red}🟥 Red Highlight}}$ = inaccessible tile; ${\textsf{\color{Goldenrod}🟨 Yellow Highlight}}$ = accessible event tile; ${\textsf{\color{Green}🟩 Green Highlight}}$ = accessible ground tile;<br/>
  ${\textsf{\color{red}🟥 红色高亮}}$ = 不可前往的图块； ${\textsf{\color{Goldenrod}🟨 黄色高亮}}$ = 可前往的事件图块； ${\textsf{\color{Green}🟩 绿色高亮}}$ = 可前往的地面图块；

  * `Left click the mouse` = only teleport to an accessible tile and trigger the event if the tile is highlighted in yellow;<br/>`right click the mouse` (*Cheating Mode*) = teleport to any tile without triggering the event.<br/>***This operation can be done continously without releasing the hotkey.***<br/>
  `单击鼠标左键` = 仅传送至可前往的目标图块，若其为黄色高亮则触发目标事件；<br/>`单击鼠标右键`（*作弊模式*） = 可传送至所有类型的图块，且避免触发事件。<br/>***可以在保持快捷键按下的期间，重复上述操作。***

* ***Item Shortcut-Keys***: The available items' icons will be in ${\textsf{\color{Cerulean}🟦 blue highlight}}$ in the item panel<br/>
***宝物调用***：左侧宝物栏中的可用宝物会以 ${\textsf{\color{Cerulean}🟦 蓝色高亮}}$，

  * For other items, press the specified alphabet key shown on the upper left corner of the icon to use it;<br/>
  对于一般宝物，按下其左上角标示的对应字母键来使用该宝物（与 Flash 版的快捷键保持一致）；

  * For Orb of Flight, first press any arrow key once, then use arrow keys to navigate to the destination floor while keeping the hotkey down, and finally, release the hotkey to confirm.<br/>
  对于飞翔灵球（楼层传送），先按下任意方向键，然后在保持快捷键按下的同时，再按方向键选择目标楼层，最后松开快捷键确认传送。

    *Cheating Mode*: Press <kbd>▲</kbd> arrow key at the beginning to bypass the restriction that "Orb of Flight can only be used when you are next to the stairs."<br/>
    *作弊模式*：一开始按下 <kbd>▲</kbd> 方向键可绕开 “只能在楼梯旁使用飞翔灵球” 这一限定。

* ***On-Map Damage***: *This feature will be turned on only when you have Orb of Hero* unless otherwise configured in the [Config (Dynamic) dialog](#patch-config--修正设置)<br/>
***地图显伤***：除非在 [设置（动态）](#patch-config--修正设置) 对话框中更改了设置，*仅当玩家拥有 勇者灵球（怪物手册）时生效*，

  * The battle damage and magic attack damage for all monsters on the current floor will be displayed in the bottom left corner of the corresponding tile;<br/>
  当前楼层所有怪物的伤害、魔法攻击的数值将显示在对应图块的左下角；

    * ${\textsf{\color{red}Red}}$ = unbeatable; additional line on top = next critical ATK gain<br/>
    ${\textsf{\color{red}红字}}$ = 无法战胜；上方额外数值 = 下一攻击临界；

    * In the backside tower (≥ 2nd-round game), the displayed damage/critical values, as well as your properties in the top left panel, will be the real values divided by 44 (*or other custom multiplication factor specified in [the cheat console](https://github.com/Z-H-Sun/tswKai/wiki/1.2.5-‐-Cheat-Console#usage)*); same below); see right figure below.<br/>
    里侧塔（二周目及以上）里的伤害/临界值，包括左上角玩家的属性栏里，显示的都将是除以 44（*或者其他由 [作弊控制台](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.5-‐-作弊控制台#用法) 指定的自定义倍数，下同*）以后的真实值（右下图）。

  * When hovering the mouse over a monster,<br/>
  将鼠标移到某个怪物上时，

    * Basic properties (namely HP, ATK, and DEF) of that monster will be displayed in property panel at bottom right;<br/>将在右下方的属性栏显示怪物的基本属性（生命力、攻击力、防御力）；

    * Detailed information, such as battle round count, damage per round, GOLD income, and critical ATK values, together with the real values divided by 44 in the backside tower (shown in brackets), etc., will be displayed in the bottom status bar.<br/>
    将在底部状态栏显示 回合数、回合伤害、金币、攻击临界值、包括里侧塔除以 44 以后的真实值（显示在方括号中） 等详细信息。

|![Map Enhancement 1](https://github.com/Z-H-Sun/tswKai/wiki/img/c1.2.2-1.png)|![Map Enhancement 2](https://github.com/Z-H-Sun/tswKai/wiki/img/1.2.2-2.png)|
|---|---|

---

### Save/Load Data / 存档相关
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.3-‐-Save／Load-Data) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.3-‐-存档相关)*

* For TSW's original 8 data slots,<br/>
对于 TSW 本身的 8 个存档位，

  <kbd>Alt</kbd>+<kbd>1</kbd>/<kbd>2</kbd>/.../<kbd>8</kbd> = load data #1-#8 / 读 1\~8 号档<br/>
  <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>1</kbd>/<kbd>2</kbd>/.../<kbd>8</kbd> = save data #1-#8 / 存 1\~8 号档

* ***Arbitrary Data***-related functions (see left figure below):<br/>
***任意存档*** 相关功能（见左下图）：

  * <kbd>Ctrl</kbd>+<kbd>L</kbd> = load any data from file / 读取任意存档文件<br/>
    <kbd>Ctrl</kbd>+<kbd>S</kbd> = save any data to file / 保存任意存档文件

  * A common file dialog will pop up. You can also do some simple file-managing operations like renaming files, deleting files, making new folders, etc.<br/>
  将会显示如下图所示的文件对话框。可以进行简单的重命名、删除文件、新建文件夹等文件管理操作。

  * The initial directory is TSW's data-save path. The initial filename is "current_date+`_1.dat`". The default extension name is `.dat`. You can view and select files with other extension names in the "File name" combo text box. When saving, if the filename already exists, it will be automatically modified to an available name.<br/>
  默认文件夹为 TSW 游戏的存储目录，默认文件名为 “当前日期+`_1.dat`”，默认扩展名为 `.dat`。可以通过 “文件名” 组合文本框查看和选择具有其他扩展名的文件。存档时，若文件名已存在，程序会自动修改为可用的文件名。

  * After confirming, check the prompt text in the bottom status bar of the TSW game window to know whether the operation is successful.<br/>
  确认后可通过魔塔游戏底部状态栏查看是否读档/存档成功。

* ***Auto Data***-related functions:<br/>
***自动存档*** 相关功能：
  * There are a total of 256 temp data slots, and once they are full, the earlier saved data with the same index will be overwritten automatically.<br/>
  总共有 256 个临时存档位，超出后会自动覆写之前更早的相同编号的临时存档；

  * Auto saving will be triggered before the checkpoints below, unless otherwise configured in the [Config (Dynamic) dialog](#patch-config--修正设置):<br/>
  除非在 [设置（动态）](#patch-config--修正设置) 对话框中更改了设置，发生以下情况之前会触发自动存档：

    Opening doors; battles; talking to altars, merchants, and 2F oldman; using items; triggering traps.<br/>
    开门、战斗、祭坛、商人、2F 老人、使用宝物、机关陷阱。

  * <kbd>Backspace</kbd> = load the previous temp data (i.e., "undo") / 读取上一个临时存档（撤销）<br/>
    <kbd>Shift</kbd>+<kbd>Backspace</kbd> = load the next temp data (i.e., "redo") / 读取下一个临时存档（重做）

    These operations can be performed multiple times until there is no previous/next temp data available.<br/>
    直至上一个/下一个临时存档不存在为止。

|![Arbitrary Data](https://github.com/Z-H-Sun/tswKai/wiki/img/c1.2.3-1.png)|![Background Music](https://github.com/Z-H-Sun/tswKai/wiki/img/1.2.4-1.png)|
|---|---|

---

### Background Music / 背景音乐
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.4-‐-Background-Music) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.4-‐-背景音乐)*

In the original version of TSW, the BGM function is very user-hostile, which is probably why it is disabled by default. This function serves to replace the buggy built-in BGM function. In addition, one BGM from TSW 3D Ver. for the phantom floor was added; the original MIDI BGMs were played and recorded using a better sound font, making the music sound more catchy than the Windows built-in MIDI timbre (right figure above).<br/>
替换了原版魔塔中，非常用户不友好的背景音乐 (BGM) 功能（这可能是其默认设为关闭状态的原因）。同时，新增一首 3D 版 TSW 中增加的音乐（幻影楼层的主题音乐），并对每一首 MIDI 乐曲使用了更逼真的音色字体进行重新录制，使其听上去比 Windows 自带的 MIDI 音色更带感（右上图）。

* The mod will, by default, take over the playback of the game's background music unless otherwise configured in the [Config (Dynamic) dialog](#patch-config--修正设置).<br/>
除非在 [设置（动态）](#patch-config--修正设置) 对话框中更改了设置，默认会完全接管游戏背景音乐的播放。

* <kbd>F3</kbd> = toggle on/off the game background music / 开启/关闭游戏背景音乐

---

### Cheat Console / 作弊控制台
*For more details, refer to its [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2.5-‐-Cheat-Console) / 更多细节详见对应的 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.5-‐-作弊控制台)*

> [!warning]
> The cheating functions should only be used for game testing or as a last resort to rescue a "dead data". Please do not rely too much on these functions; otherwise, you will not be able to enjoy the best of the TSW game.
>
> 作弊功能仅供游戏测试和临时救场用，请勿太过依赖此功能而失去魔塔游戏的最佳体验。

* During the game, press <kbd>F8</kbd> twice to enter the Cheat Console. As shown in the left figure below, a list of variables and their values will be displayed.<br/>
在游戏中途，按两次 <kbd>F8</kbd> 可以进入作弊控制台。界面将显示游戏变量列表及对应值，如左下图所示。

* Each variable is denoted as a single letter or number (labelled in yellow on the right). Press the corresponding key to select that variable, or use arrow keys to navigate to an item.<br/>
各变量在右侧以单个字母或数字表示，按下对应按键以选择该变量；或者按方向键来选定一个项目。

* Follow the instructions to input the desired new value. Note the upper and lower limits.<br/>You can use <kbd>Backspace</kbd> to clear the input, and you can press <kbd>Enter</kbd> or <kbd>Space</kbd> to confirm. When the number of digits reaches the upper limit, the value will be accepted immediately.<br/>At any time, press <kbd>ESC</kbd> to cancel, or press an arrow key to cancel and redirect to a neighboring item.<br/>
根据提示输入想要的新数值，请注意上限及下限。<br/>可用 <kbd>退格</kbd> 删除键入，按 <kbd>回车</kbd> 或 <kbd>空格</kbd> 确认。当数字位数达到上限也会自动确认并返回。<br/>中途可以按 <kbd>ESC</kbd> 取消，或者按方向键取消并重新定向到一个相邻的项目。

* After you are done, press <kbd>ESC</kbd> or <kbd>Enter</kbd> or <kbd>Space</kbd> to leave the interface and return to the TSW game.<br/>
设置结束后，按 <kbd>ESC</kbd> 或 <kbd>回车</kbd> 或 <kbd>空格</kbd> 退出控制台界面返回游戏。

|![Cheat Console](https://github.com/Z-H-Sun/tswKai/wiki/img/1.2.5-1.png)|![Mojibake](https://github.com/Z-H-Sun/tswKai/wiki/img/1.1-2.png)|
|---|---|

## Troubleshooting / 疑难解答
*For more details, refer to the "Troubleshooting" section of each [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.1-‐-Run-TSW-Game#troubleshooting) / 更多细节详见每个 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2.1-‐-运行魔塔游戏#疑难解答) 中的 “疑难解答” 一节*

* If error message boxes pop up in `tswLauncher` directly, please re-download the latest [all-in-one package](https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip). If the TSW process can be opened successfully, but it terminates in 4 seconds with a bunch of message boxes, try the `Initialize` button.<br/>
若 `tswLauncher` 直接弹出错误窗口，请重新下载最新版的 [软件整合包](https://github.com/Z-H-Sun/tswKai/releases/latest/download/TSW_all_in_one.zip)。若魔塔进程能正常打开，但弹出一堆弹窗，5 秒内魔塔程序终止，可尝试单击 `初始化` 按钮。

* In case of Mojibake (right figure above) when running the Chinese version, it is because the system locale is not in simplified Chinese, and you can open the system `Control Panel`, go to `Regions -> Administrative -> Language for non-Unicode programs`, and change it to `Chinese (Simplified, China)`.<br/>
若运行汉化版时遇到乱码（右上图），是因为操作系统的区域语言设置不是简体中文，请到系统 `控制面板`，将 `区域 -> 管理 -> 非 Unicode 的程序语言` 修改为 `中文（简体，中国）`。

* If you cannot reset the hotkey by double pressing <kbd>F7</kbd> or cannot quit by holding <kbd>F7</kbd>, please check your system's [keyboard repeat delay and keyboard repeat rate](https://thegeekpage.com/change-keyboard-repeat-rate-repeat-delay-windows-10/). With the default setting of this app, you should make sure the former is greater than 450 msec and the latter is smaller than 50 msec.<br/>
如果无法双击 <kbd>F7</kbd> 重置热键或无法长按 <kbd>F7</kbd> 退出修改器，请检查系统的 [键盘重复延迟 和 键盘重复速率](https://thegeekpage.com/change-keyboard-repeat-rate-repeat-delay-windows-10/)。在本修改器的默认设置下，前者必须长于 450 毫秒，且后者必须短于 50 毫秒。

* While the "Config (Dynamic)" or "Cheat Console" window is open, ***the TSW window will be temporarily disabled***. If you cannot find the config dialog or the console window (*which may be overlapped by the TSW game window*), press <kbd>F7</kbd> to bring it to the foreground.<br/>
在打开 “设置（动态）” 或 “作弊控制台” 窗口时，魔塔游戏窗口将 ***暂时不可用***。若中途找不到 设置 或 控制台 窗口（*有可能被魔塔游戏窗口盖住了*），可按 <kbd>F7</kbd> 将其唤至前台。

* In case the <kbd>Tab</kbd> or left <kbd>⊞ WIN</kbd> hotkey stops working (which is rare), you can quickly press <kbd>F7</kbd> twice to reset the hotkeys.<br/>
虽然不太可能发生，但如果 <kbd>Tab</kbd> 或 左侧 <kbd>⊞ WIN</kbd> 热键失效，可以快速按两下 <kbd>F7</kbd> 重置热键。

* For touchpad users:<br/>
  针对使用触摸板的用户：

  * While holding down the <kbd>Tab</kbd> key, if you cannot use the touchpad to perform left or right click, please go to `Settings -> Devices (or, “Bluetooth & devices”) -> Touchpad -> Taps -> Touchpad sensitivity` dropdown list and choose `Most sensitive`.<br/>
    如果在 <kbd>Tab</kbd> 键按下时，无法使用触摸板单击左键或右键，请前往 `设置 -> 设备（或“蓝牙和其他设备”）-> 触摸板 -> 点击 -> 触摸板敏感度` 下拉框，选取 `最高敏感度`。

  * While holding down the <kbd>⊞ WIN</kbd> key, if you cannot use the touchpad to move the cursor, please go to `Control Panel -> TouchPad -> Advanced settings`, and untick `To help prevent cursor from accidentally moving while you type, change the delay before touchpad works` (or equivalent settings); if the issue persists, also untick `Turn on PalmCheck` (or equivalent settings).<br/>
    如果在 <kbd>⊞ WIN</kbd> 键按下时无法使用触摸板移动光标，请前往 `控制面板 -> TouchPad -> 高级设置`：在 `敲击和拖动` 选项卡中，取消勾选 `键盘输入时，指定的延迟时间内禁用触摸板`（或其他类似选项）；若仍然无法工作，再将 `灵敏度` 选项卡中的 `开启手掌检测` 取消勾选（或其他类似选项）。

* In case of lag (which is rare):<br/>
  如果遇到卡顿（极少情况下才会发生）：

  * If the game lags every time the background music replays, it might be because you are running on an old, slow PC with poor performance, which requires extra time for reading and decoding MP3 files. In this case, press <kbd>F3</kbd> (*or, untick the "Options -> Background Music On" menu item in the TSW game*) to turn off the background music.<br/>
    如果每次都会在背景音乐重新开始播放的时候卡顿一下，可能是因为对于某些性能较差的旧电脑，播放 MP3 音乐时会需要一些额外的读取、解码时间，因此，请按 <kbd>F3</kbd>（*或者，取消勾选魔塔游戏的 `选项 -> 开启背景音乐` 菜单*）关闭背景音乐。

  * If the game lags every time you open a door, go up/downstairs, and battle (and the sound effects are noticeably cut off), it might be because the built-in speaker sound card of your laptop brand has poor performance (possibly due to energy saving considerations). In this case, simply plugging in external speakers or headphones can solve the problem; or, untick the "Options -> Wav Sound On" menu item of the TSW game to turn off the sound effects.<br/>
    如果每次都在开门、上下楼、战斗时卡顿一下（同时音效有明显“掐头去尾”感），可能是由于某些品牌的笔记本电脑内置扬声器声卡性能较差（也有可能是出于节能设置），此时插入外接音箱或耳机就可解决；或者，取消勾选魔塔游戏的 `选项 -> 开启音效` 菜单以关闭音效。

* If you encounter any problems, please follow the instructions provided by this mod. If the problem persists, please [submit an issue here](https://github.com/Z-H-Sun/tswKai/issues/new).<br/>
如果遇到问题，请按照本修改器弹出的提示文本操作。如果仍然无法解决问题，请 [提交 Issue](https://github.com/Z-H-Sun/tswKai/issues/new)。

## Advanced Options / 高级设置
*For more details, refer to the "Advanced Options" section of each [Wiki page](https://github.com/Z-H-Sun/tswKai/wiki/1.2-‐-Run-tswKai3#advanced-options) / 更多细节详见每个 [百科页面](https://github.com/Z-H-Sun/tswKai/wiki/§1.2-‐-运行修改器#高级设置) 中的 “高级设置” 一节*

> [!warning]
> The behavior of this mod can be configured according to this section. However, misconfiguration (especially for users who are not familiar with the Ruby language) will cause uncontrolled or undefined behaviors of this app. In such cases, please delete `tswKai3Option.txt` to reset.
>
> 参考本节的内容可配置修改器的行为。但是，配置不当（特别是对 Ruby 语言不是很了解的用户）将导致程序的行为不可控。此时请删除 `tswKai3Option.txt` 以重置。

* Use any text editor to open `tswKai3Option.txt` in the same folder as `tswKai3.exe`. If the file does not exist, create one. It is recommended to start from this exemplary [`tswKai3Option.txt`](https://github.com/Z-H-Sun/tswKai/blob/v3.1.5/tswKai3Option.txt) file (which is included in the all-in-one package).<br/>
使用任意文本编辑器打开 `tswKai3.exe` 同目录下的 `tswKai3Option.txt`，如果该文件不存在则新建一个同名文件。推荐在此样例 [`tswKai3Option.txt`](https://github.com/Z-H-Sun/tswKai/blob/v3.1.5/tswKai3Option.txt) 文件的基础上进行修改（软件整合包中已包含此样例文件）。

* This config file uses Ruby language. In Ruby, the pound sign (#) will comment out everything after it on the same line, so the "uncomment" instruction below means deleting the pound sign (#) at the beginning of the line so as to make this line take effect.<br/>
此配置文件使用 Ruby 语言。在 Ruby 中，井号 (#) 表示注释掉这一行内、在它之后的所有内容，故以下说明中“取消注释”的做法即是删掉行首的井号 (#) 以使该行代码生效。

* For example, the mod will, by default, use the same language as the currently running TSW game (English vs. Chinese), but if you delete the leading pound sign in Line 21 of the exemplary option file as follows, the mod will always be displayed in English: `$isCHN = nil`.<br/>
例如，修改器默认使用与当前运行中的魔塔游戏相同的语言（中文或英文），而删除样例配置文件第 19 行代码开头的井号（如后所示），表示总是使用中文作为修改器的显示语言：`$isCHN = 1`。

* If you have been familiar with the usage of this mod after using it for several times, and you would like to focus on the strategic calculations and route optimizations, it is advisable to uncomment the 12th, 16th, 42nd, 44th, 46th, and 48th lines in the exemplary option file to minimize distraction (meaning: always show on-map damage, disable BGM enhancement, hide the config dialog on startup, hide the tutorial message box on startup, skip asking whether to hibernate on quitting, and hide the TSW status window, respectively):<br/>
如果经过多次运行，你已经熟悉了本修改器的用法，并且希望专注于路线计算和优化，则可以对样例配置文件中的第 12、16、42、44、46、48 行取消注释以降低干扰（分别表示：总是显示地图伤害、关闭 BGM 增强、启动时不显示设置窗口、启动时不显示使用教程提示框、退出时不询问是否待机、不显示 TSW 状态窗口）：

  ```ruby
  $MPshowMapDmg = 1
  $BGMtakeOver = false # Default: true
  $CONonTSWstartup = false # Default: true
  $CONmsgOnTSWstartup = false # Default: true
  $CONaskOnTSWquit = false # Default: true
  $CONshowStatusTip = false # Default: true
  ```

## Developers / 开发者文档（英文）

Wanna run the code of the mod yourself? Sure! Benefits are obvious, and it can be simpile!

Any Ruby version between 1.8 and 2.7 is all you need.

Read the Wiki page's [Developers](https://github.com/Z-H-Sun/tswKai/wiki/2-‐-Developers) chapter, and please fork my project if you would like to contribute!
