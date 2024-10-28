; UTF-8 with BOM
#NoEnv  ; 推荐使用
#SingleInstance Force  ; 确保只运行一个实例
#InstallKeybdHook
#InstallMouseHook     ; 安装鼠标钩子
SetWorkingDir %A_ScriptDir%
SetBatchLines -1      ; 脚本全速执行
Process, Priority, , High  ; 设置进程优先级为高

; 定义标志变量和计数器
global isRunning := false
global counter := 0
global isPaused := false  ; 添加暂停状态标志

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

; 添加技能设置区域
Gui, Add, GroupBox, x10 y140 w460 h320, 按键设置

; 添加列标题
Gui, Add, Text, x30 y170 w60 h20, 按键
Gui, Add, Text, x130 y170 w60 h20, 启用
Gui, Add, Text, x200 y170 w120 h20, 间隔(毫秒)

; 技能1-4设置
Loop, 4 
{
    yPos := 200 + (A_Index-1) * 35
    Gui, Add, Text, x30 y%yPos% w60 h20, 技能%A_Index%:
    Gui, Add, Hotkey, x90 y%yPos% w35 h20 vSkill%A_Index%Key, %A_Index%
    Gui, Add, Checkbox, x130 y%yPos% w60 h20 vSkill%A_Index%Enable Checked, 启用
    Gui, Add, Edit, x200 y%yPos% w60 h20 vSkill%A_Index%Interval Number, 300
}

; 鼠标按键设置
Gui, Add, Text, x30 y340 w60 h20, 左键:
Gui, Add, Checkbox, x130 y340 w60 h20 vLeftClickEnable Checked, 启用
Gui, Add, Edit, x200 y340 w60 h20 vLeftClickInterval Number, 80

Gui, Add, Text, x30 y375 w60 h20, 右键:
Gui, Add, Checkbox, x130 y375 w60 h20 vRightClickEnable, 启用
Gui, Add, Edit, x200 y375 w60 h20 vRightClickInterval Number, 300

; 添加保存按钮
Gui, Add, Button, x30 y420 w100 h30 gSaveSettings, 保存设置

; 添加状态栏
Gui, Add, StatusBar,, 就绪

; 显示GUI
Gui, Show, w480 h500, 暗黑4助手

; 只在暗黑破坏神4窗口活动时启用以下热键和功能
#If WinActive("ahk_class Diablo IV Main Window Class")

; 当按下F1时触发宏
F1::
ToggleMacro:
    isRunning := !isRunning  ; 切换运行状态
    if (isRunning) {
        isPaused := false  ; 重置暂停状态
        ; 为每个启用的按键设置定时器
        Loop, 4 
        {
            GuiControlGet, enabled,, Skill%A_Index%Enable
            if (enabled) {
                GuiControlGet, interval,, Skill%A_Index%Interval
                SetTimer, PressSkill%A_Index%, %interval%
            }
        }
        
        ; 设置鼠标按键定时器
        GuiControlGet, leftEnabled,, LeftClickEnable
        if (leftEnabled) {
            GuiControlGet, leftInterval,, LeftClickInterval
            SetTimer, PressLeftClick, %leftInterval%
        }
        
        GuiControlGet, rightEnabled,, RightClickEnable
        if (rightEnabled) {
            GuiControlGet, rightInterval,, RightClickInterval
            SetTimer, PressRightClick, %rightInterval%
        }
        
        GuiControl,, StatusText, 状态: 运行中
        SB_SetText("宏已启动")
    } else {
        isPaused := false  ; 重置暂停状态
        ; 关闭所有定时器
        Loop, 4 {
            SetTimer, PressSkill%A_Index%, Off
        }
        SetTimer, PressLeftClick, Off
        SetTimer, PressRightClick, Off
        
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

; 按键发送函数
PressSkill1:
    if (isRunning && !isPaused) {
        GuiControlGet, key,, Skill1Key
        if (key != "") {
            Send, {%key%}
        }
    }
return

PressSkill2:
    if (isRunning && !isPaused) {
        GuiControlGet, key,, Skill2Key
        if (key != "") {
            Send, {%key%}
        }
    }
return

PressSkill3:
    if (isRunning && !isPaused) {
        GuiControlGet, key,, Skill3Key
        if (key != "") {
            Send, {%key%}
        }
    }
return

PressSkill4:
    if (isRunning && !isPaused) {
        GuiControlGet, key,, Skill4Key
        if (key != "") {
            Send, {%key%}
        }
    }
return

PressLeftClick:
    if (isRunning && !isPaused) {
        Click
    }
return

PressRightClick:
    if (isRunning && !isPaused) {
        Click right
    }
return

; 保存设置到配置文件
SaveSettings:
    ; 保存所有设置到配置文件
    FileDelete, settings.ini
    Loop, 4 {
        GuiControlGet, key,, Skill%A_Index%Key
        GuiControlGet, enabled,, Skill%A_Index%Enable
        GuiControlGet, interval,, Skill%A_Index%Interval
        IniWrite, %key%, settings.ini, Skills, Skill%A_Index%Key
        IniWrite, %enabled%, settings.ini, Skills, Skill%A_Index%Enable
        IniWrite, %interval%, settings.ini, Skills, Skill%A_Index%Interval
    }
    
    GuiControlGet, leftEnabled,, LeftClickEnable
    GuiControlGet, leftInterval,, LeftClickInterval
    GuiControlGet, rightEnabled,, RightClickEnable
    GuiControlGet, rightInterval,, RightClickInterval
    
    IniWrite, %leftEnabled%, settings.ini, Mouse, LeftClickEnable
    IniWrite, %leftInterval%, settings.ini, Mouse, LeftClickInterval
    IniWrite, %rightEnabled%, settings.ini, Mouse, RightClickEnable
    IniWrite, %rightInterval%, settings.ini, Mouse, RightClickInterval
    
    SB_SetText("设置已保存")
return

; GUI关闭处理
GuiClose:
GuiEscape:
ExitApp
return

; 在#If WinActive("ahk_class Diablo IV Main Window Class")下添加Tab键处理
Tab::
    if (!isRunning) {
        return
    }
    
    isPaused := !isPaused
    
    if (isPaused) {
        ; 暂停所有定时器
        Loop, 4 {
            GuiControlGet, enabled,, Skill%A_Index%Enable
            if (enabled) {
                SetTimer, PressSkill%A_Index%, Off
            }
        }
        
        GuiControlGet, leftEnabled,, LeftClickEnable
        if (leftEnabled) {
            SetTimer, PressLeftClick, Off
        }
        
        GuiControlGet, rightEnabled,, RightClickEnable
        if (rightEnabled) {
            SetTimer, PressRightClick, Off
        }
        
        GuiControl,, StatusText, 状态: 已暂停
        SB_SetText("宏已暂停")
    } else {
        ; 恢复所有启用的定时器
        Loop, 4 {
            GuiControlGet, enabled,, Skill%A_Index%Enable
            if (enabled) {
                GuiControlGet, interval,, Skill%A_Index%Interval
                SetTimer, PressSkill%A_Index%, %interval%
            }
        }
        
        GuiControlGet, leftEnabled,, LeftClickEnable
        if (leftEnabled) {
            GuiControlGet, leftInterval,, LeftClickInterval
            SetTimer, PressLeftClick, %leftInterval%
        }
        
        GuiControlGet, rightEnabled,, RightClickEnable
        if (rightEnabled) {
            GuiControlGet, rightInterval,, RightClickInterval
            SetTimer, PressRightClick, %rightInterval%
        }
        
        GuiControl,, StatusText, 状态: 运行中
        SB_SetText("宏已继续")
    }
return
