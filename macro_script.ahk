; UTF-8 with BOM
#NoEnv  ; 推荐使用
#SingleInstance Force  ; 确保只运行一个实例
#InstallKeybdHook
#InstallMouseHook     ; 安装鼠标钩子
SetWorkingDir %A_ScriptDir%
SetBatchLines -1      ; 脚本全速执行
Process, Priority, , High  ; 设置进程优先级为高

; 设置UTF-8编码和代码页
; FileEncoding, UTF-8-RAW

; 定义标志变量和计数器
global isRunning := false
global counter := 0

; 创建GUI
Gui, +AlwaysOnTop
Gui, Color, FFFFFF ; 白色背景
Gui, Font, s10, Microsoft YaHei UI

; 添加主要内容区域
Gui, Add, GroupBox, x10 y10 w460 h120, 状态
Gui, Add, Text, x30 y35 w100 h20 vStatusText, 状态: 未运行
Gui, Add, Button, x30 y65 w120 h30 gToggleMacro, 开始/停止(F1)
Gui, Add, Text, x170 y70 w200 h20, F3: 卡移速
Gui, Add, Text, x30 y100 w300 h20, 提示：仅在暗黑破坏神4窗口活动时生效

; 添加设置区域
Gui, Add, GroupBox, x10 y140 w460 h280, 设置
; 在这里添加设置选项,比如:
Gui, Add, Text, x30 y170 w120 h20, 按键间隔(毫秒):
Gui, Add, Edit, x160 y170 w60 h20 vKeyInterval Number, 80
Gui, Add, Text, x30 y200 w120 h20, 技能循环间隔:
Gui, Add, Edit, x160 y200 w60 h20 vSkillInterval Number, 6

; 添加状态栏
Gui, Add, StatusBar,, 就绪

; 显示GUI
Gui, Show, w480 h460, 暗黑4助手

; 只在暗黑破坏神4窗口活动时启用以下热键和功能
#If WinActive("ahk_class Diablo IV Main Window Class")

; 当按下F1时触发宏
F1::
ToggleMacro:
    isRunning := !isRunning  ; 切换运行状态
    if (isRunning) {
        GuiControlGet, KeyInterval
        SetTimer, MacroLoop, %KeyInterval%  ; 使用设置的间隔时间
        GuiControl,, StatusText, 状态: 运行中
        SB_SetText("宏已启动")
    } else {
        SetTimer, MacroLoop, Off  ; 如果停止运行,关闭计时器
        GuiControl,, StatusText, 状态: 已停止
        SB_SetText("宏已停止")
    }
return

; 卡移速
F3::
SendKeys() ;
return

SendKeys() {
    Send, r ;
    Sleep, 10
    Send, {Space} ;
    Sleep, 500
    Send, r ;
}

; 宏循环函数
MacroLoop:
    if (isRunning) {
        GuiControlGet, SkillInterval
        if (Mod(counter, SkillInterval) == 0) {  ; 使用设置的技能循环间隔
            Send, 1234  ; 同时发送1234
        }
        Click  ; 每次循环都点击鼠标左键
        counter++
    }
return

#If  ; 结束特定窗口的条件

; GUI关闭处理
GuiClose:
GuiEscape:
ExitApp
return
