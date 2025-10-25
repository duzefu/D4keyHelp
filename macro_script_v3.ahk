#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority "High"

; 允许热键中断正在运行的线程
#MaxThreadsPerHotkey 2

; ========== 包含所有模块 ==========
; 全局变量定义
#Include "core/GlobalVars.ahk"

; 工具类
#Include "utils/Logger.ahk"
#Include "utils/Settings.ahk"

; 核心功能
#Include "core/WindowManager.ahk"
#Include "core/TimerManager.ahk"
#Include "core/MacroControl.ahk"

; GUI模块
#Include "gui/MainGUI.ahk"
#Include "gui/SkillControls.ahk"
#Include "gui/MouseControls.ahk"

; 功能模块
#Include "functions/SkillSystem.ahk"
#Include "functions/MouseActions.ahk"
#Include "functions/UtilityActions.ahk"

; 热键定义
#Include "hotkeys/GameHotkeys.ahk"

; ========== 程序启动 ==========
; 初始化GUI并启动程序
InitializeGUI()