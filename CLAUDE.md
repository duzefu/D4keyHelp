# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

D4KeyHelp是一个为暗黑破坏神4设计的图形化宏工具，具有可自定义配置功能。使用AutoHotkey v2.0构建，提供：
- 基于GUI的技能、鼠标动作和功能键配置
- 带有暂停/恢复功能的战斗宏
- 多种技能激活模式（连点、维持BUFF、按住）
- 鼠标自动化和移动模式
- 通过INI文件持久化设置

## 开发命令

**运行应用程序：**
```bash
# 源码方式：主程序入口
D4keyHelp.ahk

# 编译版本：使用可执行文件
D4keyHelp.exe
```

**无构建命令** - 直接运行 AutoHotkey 脚本。

**测试（tests/）：推荐用 `tests/run.sh`，它把三步串起来并自动探测解释器路径：**
```bash
bash tests/run.sh                 # 依次跑：加载期校验 → 冒烟测试 → 血球回归
bash tests/run.sh validate        # 只跑加载期校验（最快，改完立刻自检用）
bash tests/run.sh smoke           # 只跑冒烟测试
bash tests/run.sh globe           # 只跑血球回归
bash tests/run.sh globe --export  # 血球回归前重新生成 tests/data/*.bin
```
退出码：`0` 全部通过，`1` 有失败项，`2` 环境不满足（找不到解释器等）。
解释器可用 `AHK=/path/to/AutoHotkey64.exe bash tests/run.sh` 覆盖。

手工单独跑某个脚本也可以，但必须注意下面几点（`run.sh` 已经处理好）：

- **解释器不在 PATH 上**，`AutoHotkey64.exe` 直接敲会 command not found；
  实际路径是 `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe`。
- **开关要写双斜杠**。MSYS/Git-Bash 会把 `/validate` 改写成 Windows 路径
  （变成 `C:/Program Files/Git/validate`），AHK 收到的是个不存在的脚本名而不是开关，
  于是脚本被真的执行、进程挂住不退出。`MSYS_NO_PATHCONV=1` 也能挡住改写，但它同时会
  把 `/c/...` 形式的脚本路径也一并破坏，所以统一用 `//validate` 这种双斜杠写法。
- **加载期报错时 AHK 默认弹对话框等用户点确定**，非交互环境下会永久挂住。
  实测（2.0.2）：`//ErrorStdOut` 只对**语法错误**和 **`#Include` 找不到目标**有效
  （消息发到 stderr、进程正常退出、退出码 2）；而**调用不存在的函数**这类加载期错误
  仍会弹窗（`try/catch` 也拦不住，因为它在加载阶段就报错），此时只能靠外层 `timeout` 兜底
  （`run.sh` 里默认 30 秒，校验步骤单独收紧到 10 秒）。
- **开关必须写在脚本前面**。AHK 用法是 `AutoHotkey.exe [开关...] [脚本] [脚本参数...]`；
  写成 `AutoHotkey64.exe script.ahk //validate` 时开关会被当成**传给脚本的参数**而静默失效，
  脚本被真的执行——对 `D4keyHelp.ahk` 就是启动整个宏程序并挂住。

```bash
AHK="/c/Program Files/AutoHotkey/v2/AutoHotkey64.exe"
"$AHK" //validate //ErrorStdOut D4keyHelp.ahk   # 退出码 0=能加载，非 0=有加载期错误
python tests/ExportGlobeWindows.py              # 生成 tests/data/*.bin（需 Pillow，截图为本地文件）
"$AHK" tests/HealthGlobeTest.ahk                # 结果写入 tests/result.txt
"$AHK" tests/SmokeTest.ahk                      # 结果写入 tests/smoke_result.txt
```

`//validate` 查的是**加载期**问题（语法错误、`#Include` 目标不存在、调用了不存在的函数），
不做运行时检查（例如类型不匹配、数组越界要等真跑到那行才知道）。
好处是极快（约 0.1 秒）且不创建界面，适合改完代码立刻自检。
注意：碰到「调用不存在的函数」这类错误它会弹窗卡住（见上文），
所以手工敲命令时也建议套一层 `timeout 30`。

注意 `python` 与 `python3` 不是同一个解释器：本机 `python`(3.14) 有 Pillow，
`python3` 是 WindowsApps 里的 3.13、**没有** Pillow，所以生成 `*.bin` 要用 `python`
（`run.sh` 会自动挑带 Pillow 的那个）。

运行测试前先确认没有正在跑的应用实例（`#SingleInstance` 相关行为），且测试会创建测试目录下的
`settings.ini`/`debugd4.log`，不会碰用户配置。

**冒烟测试的退出码不可信**：`SmokeTest.ahk` 内部用 `try/catch` 兜住异常，进程退出码恒为 0，
所以只能看 `tests/smoke_result.txt` 里有没有「失败」「异常」字样（`run.sh` 就是这么判的）。

## 架构和核心组件

### 主应用文件
- `D4keyHelp.ahk` - 模块化主入口文件（与项目同名）

### 模块化文件结构
```
├── core/                    # 核心功能模块
│   ├── GlobalVars.ahk      # 全局变量定义
│   ├── WindowManager.ahk   # 窗口状态管理
│   ├── TimerManager.ahk    # 定时器控制
│   └── MacroControl.ahk    # 宏运行控制
├── gui/                    # GUI界面模块
│   ├── MainGUI.ahk         # 主界面创建
│   ├── SkillControls.ahk   # 技能控件
│   └── MouseControls.ahk   # 鼠标控件
├── functions/              # 功能实现模块
│   ├── SkillSystem.ahk     # 技能系统
│   ├── MouseActions.ahk    # 鼠标动作
│   ├── UtilityActions.ahk  # 功能键动作（含通用屏幕抓取 CaptureScreenRegion）
│   ├── HealthGlobe.ahk     # 血球自动识别 + 血量估算（条件喝药的感知层）
│   └── ConditionSystem.ahk # 条件判定（是否该喝药）与界面动作
├── utils/                  # 工具类模块
│   ├── Logger.ahk          # 日志记录
│   ├── Lang.ahk            # 界面多语言（中文 / English）语言表与 L() 取值函数
│   └── Settings.ahk        # 设置管理
├── hotkeys/               # 热键定义模块
│   └── GameHotkeys.ahk    # 游戏热键
└── tests/                  # 开发用测试（回归 + 冒烟）
```

### 核心架构模式

**全局状态管理：**
- 使用全局变量管理应用状态（`isRunning`、`isPaused`等）
- 使用Map数据结构组织控件（`skillControls`、`mouseControls`）
- 函数内静态变量用于本地状态持久化

**基于定时器的自动化：**
- 使用`SetTimer()`调用周期性动作（技能、鼠标点击、移动）
- 绑定的函数对象存储在全局映射中用于定时器管理
- 协调的定时器启动/停止用于宏控制

**GUI框架：**
- 自定义GUI创建与分组控件
- 基于事件驱动的架构，使用`.OnEvent()`回调
- 实时状态更新和进度指示

**设置系统：**
- INI文件持久化（`settings.ini`）
- 不同设置类别的独立保存/加载函数
- 缺失配置的默认值回退

### 关键功能区域

**技能系统（`functions/SkillSystem.ahk`）：**
- 三种模式：连点、维持BUFF、按住
- 像素颜色检测用于BUFF状态检查
- 独立技能定时器管理

**鼠标控制（`functions/MouseActions.ahk`）：**
- 左右键自动化，支持模式切换
- 持续鼠标动作的按住状态跟踪
- Shift修饰键集成

**窗口管理（`core/WindowManager.ahk`）：**
- 暗黑4活动窗口检测
- 窗口焦点变化时自动暂停/恢复
- 窗口状态与宏状态的状态同步

**鼠标移动自动化（`functions/MouseActions.ahk` 的 `MoveMouseToNextPoint()`）：**
- 六点屏幕移动模式
- 屏幕分辨率自适应定位
- 可配置移动间隔

**血量检测 / 条件喝药（`functions/HealthGlobe.ahk` + `functions/ConditionSystem.ahk`）：**
- 按屏幕尺寸推算血球区域（2K 下圆心 = 屏幕宽/2-465, 屏幕高-116，半径 90），区域内自动定位液面
- 结论按"圆缺面积占比"换算成血量百分比；护盾覆盖血球（球体变品红）时判定为读不到血量
- 读取失败退回按间隔定时喝药；护盾策略见界面上的「护盾遮挡时不喝药」
- 像素判据与标定值都写在 `HealthGlobe.ahk` 顶部注释里，改动后必须重跑 `tests/HealthGlobeTest.ahk`

**界面多语言（`utils/Lang.ahk`）：**
- 所有界面文字统一用 `L("key")` 取当前语言，需要插值的用 `L("key", 参数…)` 替换 `{1}`、`{2}`
- 语言表 `LANG_TABLE` 按 key 存 `zh` / `en` 两列；新增文案必须两列都写，缺失会回落到中文
- 语言存在 `settings.ini` 的 `[UI] Language`（`zh` 默认 / `en`），`Lang_Init()` 在脚本加载时读一次
- 右上角语言按钮走 `ToggleLanguage()`（在 `gui/MainGUI.ahk`，与 `ToggleTheme()` 对称）：保存设置 → `Reload()`
- 语言是开关型而不是运行期替换：控件文字在创建时定下来，所以切换语言靠重载脚本
- 状态栏状态用状态键而不是文字判断颜色（`UpdateStatus("running"|"paused"|…)`），避免翻译影响配色
- 一律不翻译：`debugd4.log` 的日志内容、INI 的键名、`settings.ini` 里存的策略序号（下拉框存的是序号，所以改文案不会影响老配置）

## 配置文件

- `settings.ini` - 持久设置存储，包含技能、鼠标和功能键部分
- 使用标准INI格式，UTF-16编码
- 首次运行时自动创建默认设置
- `[UI]` 段存界面外观：`Theme`（light/dark）、`Language`（zh/en）
- 加载顺序：`utils/Lang.ahk` 必须排在 `core/GlobalVars.ahk` 之前（策略名与预设默认名在定义时就要按语言取值）

## 重要实现说明

- **需要AutoHotkey v2.0** - 与v1.3不兼容
- **窗口特定热键** - 所有热键仅在暗黑4窗口激活时工作
- **定时器协调** - 所有自动化使用协调的定时器启动/停止以防止冲突
- **状态恢复** - 宏停止时全面释放按键以防止按键卡住
- **像素检测** - 使用屏幕像素颜色检测BUFF状态（2K分辨率优化）

## 开发考虑

- 应用程序针对特定的暗黑4 UI布局（技能栏在中下方）
- 技能位置的硬编码屏幕坐标（针对2K分辨率优化）
- 广泛的调试日志系统写入`debugd4.log`
- 除AutoHotkey v2.0运行时外无外部依赖
- 新增或修改界面文案时，改的是 `utils/Lang.ahk` 的语言表，不要在控件代码里直接写中文；英文比中文长，注意控件宽度是否够（烟测能验证脚本能加载，但不会验证文字被截断）
- 文档有两份：`README.md`（中文，仓库默认显示）和 `README_EN.md`（英文），顶部互相有语言切换链接；改了一份要同步另一份