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
# 推荐：使用重构后的模块化版本
macro_script_v3.ahk

# 传统方式：单文件版本
macro_script_v2.ahk

# 编译版本：使用可执行文件
macro_script_v2.exe
```

**无构建命令** - 直接运行 AutoHotkey 脚本。

**测试（tests/）：**
```bash
# 回归测试：用四张 2K 参考截图的真实像素验证血球识别（无需启动游戏）
python tests/ExportGlobeWindows.py      # 生成 tests/data/*.bin（需 Pillow，截图为本地文件）
AutoHotkey64.exe tests/HealthGlobeTest.ahk   # 结果写入 tests/result.txt

# 冒烟测试：加载全部模块并创建界面，1.5 秒后自动退出
AutoHotkey64.exe tests/SmokeTest.ahk    # 结果写入 tests/smoke_result.txt
```

运行测试前先确认没有正在跑的应用实例（`#SingleInstance` 相关行为），且测试会创建测试目录下的
`settings.ini`/`debugd4.log`，不会碰用户配置。

## 架构和核心组件

### 主应用文件
- `macro_script_v3.ahk` - 重构后的模块化主入口文件（推荐使用）
- `macro_script_v2.ahk` - 传统单文件版本（1200+行）

### 模块化文件结构（v3）
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

**技能系统（`macro_script_v2.ahk:397-456`）：**
- 三种模式：连点、维持BUFF、按住
- 像素颜色检测用于BUFF状态检查
- 独立技能定时器管理

**鼠标控制（`macro_script_v2.ahk:504-601`）：**
- 左右键自动化，支持模式切换
- 持续鼠标动作的按住状态跟踪
- Shift修饰键集成

**窗口管理（`macro_script_v2.ahk:225-256`）：**
- 暗黑4活动窗口检测
- 窗口焦点变化时自动暂停/恢复
- 窗口状态与宏状态的状态同步

**鼠标移动自动化（`macro_script_v2.ahk:1126-1158`）：**
- 六点屏幕移动模式
- 屏幕分辨率自适应定位
- 可配置移动间隔

**血量检测 / 条件喝药（`functions/HealthGlobe.ahk` + `functions/ConditionSystem.ahk`）：**
- 按屏幕尺寸推算血球区域（2K 下圆心 = 屏幕宽/2-465, 屏幕高-116，半径 90），区域内自动定位液面
- 结论按"圆缺面积占比"换算成血量百分比；护盾覆盖血球（球体变品红）时判定为读不到血量
- 读取失败退回按间隔定时喝药；护盾策略见界面上的「护盾遮挡时不喝药」
- 像素判据与标定值都写在 `HealthGlobe.ahk` 顶部注释里，改动后必须重跑 `tests/HealthGlobeTest.ahk`

## 配置文件

- `settings.ini` - 持久设置存储，包含技能、鼠标和功能键部分
- 使用标准INI格式，UTF-16编码
- 首次运行时自动创建默认设置

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