#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority "High"

; 全局变量定义
global DEBUG := true
global debugLogFile := A_ScriptDir "\debugd4.log"
global isRunning := false
global counter := 0
global isPaused := false
global previouslyPaused := false
global myGui := ""
global statusText := ""
global skillControls := Map()
global mouseControls := {}
global statusBar := ""
global shiftEnabled := false
global utilityControls := {}
global skillActiveState := false
global skillPositions := Map(
    1, {x: 1035, y: 1290},
    2, {x: 1035 + 84, y: 1290},
    3, {x: 1035 + 84 * 2, y: 1290},
    4, {x: 1035 + 84 * 3, y: 1290},
    "left", {x: 1035 + 84 * 4, y: 1290},
    "right", {x: 1035 + 84 * 5, y: 1290}
)
global skillBuffControls := Map()
global boundSkillTimers := Map()  ; 存储绑定的技能定时器函数

; 调试输出函数
DebugLog(message) {
    if DEBUG {
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        FileAppend timestamp " - " message "`n", debugLogFile
    }
}

; 创建主窗口
myGui := Gui("", "暗黑4助手")
myGui.BackColor := "FFFFFF"
myGui.SetFont("s10", "Microsoft YaHei UI")

; 添加主要内容区域
myGui.AddGroupBox("x10 y10 w460 h120", "状态")
statusText := myGui.AddText("x30 y35 w100 h20", "状态: 未运行")
myGui.AddButton("x30 y65 w120 h30", "开始/停止(F1)").OnEvent("Click", ToggleMacro)
myGui.AddText("x170 y70 w200 h20", "F3: 卡移速")
myGui.AddText("x30 y100 w300 h20", "提示：仅在暗黑破坏神4窗口活动时生效")

; 添加技能设置区域 - 调整 GroupBox 高度
myGui.AddGroupBox("x10 y140 w460 h350", "键设置")

; 添加Shift键勾选框 - 调整位置
myGui.AddCheckbox("x30 y165 w100 h20", "按住Shift").OnEvent("Click", ToggleShift)

; 添加列标题 - 调整位置
myGui.AddText("x30 y195 w60 h20", "按键")
myGui.AddText("x130 y195 w60 h20", "启用")
myGui.AddText("x200 y195 w120 h20", "间隔(毫秒)")

; 技能1-4设置 - 减小间距
skillControls := Map()
Loop 4 {
    yPos := 225 + (A_Index-1) * 30
    myGui.AddText("x30 y" yPos " w60 h20", "技能" A_Index ":")
    skillControls[A_Index] := {
        key: myGui.AddHotkey("x90 y" yPos " w35 h20", A_Index),
        enable: myGui.AddCheckbox("x130 y" yPos " w60 h20", "启用"),
        interval: myGui.AddEdit("x200 y" yPos " w60 h20", "300")
    }
    skillBuffControls[A_Index] := myGui.AddCheckbox("x270 y" yPos " w100 h20", "维持BUFF")
}

; 鼠标按键设置 - 调整位置
mouseControls := {
    left: {
        enable: myGui.AddCheckbox("x130 y345 w60 h20", "启用"),
        interval: myGui.AddEdit("x200 y345 w60 h20", "80")
    },
    right: {
        enable: myGui.AddCheckbox("x130 y375 w60 h20", "启用"),
        interval: myGui.AddEdit("x200 y375 w60 h20", "300")
    }
}
myGui.AddText("x30 y345 w60 h20", "左键:")
myGui.AddText("x30 y375 w60 h20", "右键:")

; 添加功能键设置 - 调整位置
myGui.AddText("x30 y405 w60 h20", "翻滚:")
myGui.AddText("x30 y435 w60 h20", "喝药:")

utilityControls := {
    dodge: {
        key: myGui.AddText("x90 y405 w35 h20", "空格"),
        enable: myGui.AddCheckbox("x130 y405 w60 h20", "启用"),
        interval: myGui.AddEdit("x200 y405 w60 h20", "1000")
    },
    potion: {
        key: myGui.AddHotkey("x90 y435 w35 h20", "q"),
        enable: myGui.AddCheckbox("x130 y435 w60 h20", "启用"),
        interval: myGui.AddEdit("x200 y435 w60 h20", "15000")
    }
}

; 添加保存按钮 - 调整位置
myGui.AddButton("x30 y470 w100 h30", "保存设置").OnEvent("Click", SaveSettings)

; 添加状态栏
statusBar := myGui.AddStatusBar(, "就绪")

; 显示GUI
myGui.Show("w480 h550")

; 加载设置
LoadSettings()

; 窗口切换检查函
CheckWindow() {
    static lastState := false
    currentState := WinActive("ahk_class Diablo IV Main Window Class")
    
    if (currentState != lastState) {
        OnWindowChange()
        lastState := currentState
    }
}

; 窗口切换事件处理
OnWindowChange() {
    global isRunning, isPaused, previouslyPaused
    
    if (!WinActive("ahk_class Diablo IV Main Window Class")) {
        if (isRunning) {
            previouslyPaused := isPaused
            if (!isPaused) {
                StopAllTimers()
                isPaused := true
                statusText.Value := "状态: 已暂停(窗口切换)"
                statusBar.Text := "宏已暂停 - 窗口未激活"
            }
        }
    } else if (isRunning && isPaused && !previouslyPaused) {
        StartAllTimers()
        isPaused := false
        statusText.Value := "状态: 运行中"
        statusBar.Text := "宏已恢复 - 窗口已激活"
    }
}

; 启动所有定时器
StartAllTimers() {
    ; 先确保所有定时器都已停止
    StopAllTimers()
    
    ; 然后重新启动需要的定时器
    Loop 4 {
        if (skillControls[A_Index].enable.Value = 1) {
            interval := skillControls[A_Index].interval.Value
            ; 创建并保存绑定函数
            boundSkillTimers[A_Index] := PressSkill.Bind(A_Index)
            SetTimer(boundSkillTimers[A_Index], interval)
            DebugLog("启动技能" A_Index "定时器，间隔: " interval)
        }
    }
    
    if (mouseControls.left.enable.Value = 1) {
        SetTimer PressLeftClick, mouseControls.left.interval.Value
        DebugLog("启动左键定时器 - 间隔: " mouseControls.left.interval.Value)
    }
    
    if (mouseControls.right.enable.Value = 1) {
        SetTimer PressRightClick, mouseControls.right.interval.Value
        DebugLog("启动右键定时器 - 间隔: " mouseControls.right.interval.Value)
    }
    
    if (utilityControls.dodge.enable.Value = 1) {
        SetTimer PressDodge, utilityControls.dodge.interval.Value
        DebugLog("启动翻滚定时器")
    }
    
    if (utilityControls.potion.enable.Value = 1) {
        SetTimer PressPotion, utilityControls.potion.interval.Value
        DebugLog("启动喝药定时器")
    }
}

; 停止所有定时器
StopAllTimers() {
    ; 确保每个技能定时器都被停止
    Loop 4 {
        if boundSkillTimers.Has(A_Index) {
            SetTimer(boundSkillTimers[A_Index], 0)  ; 使用保存的绑定函数引用来停止定时器
            boundSkillTimers.Delete(A_Index)  ; 删除引用
            DebugLog("停止技能" A_Index "定时器")
        }
    }
    
    ; 停止鼠标定时器
    SetTimer PressLeftClick, 0
    SetTimer PressRightClick, 0
    
    ; 停止功能键定时器
    SetTimer PressDodge, 0
    SetTimer PressPotion, 0
    
    DebugLog("已停止所有定时器")
}

; 按键功能实现
PressSkill(skillNum) {
    if (isRunning && !isPaused && skillControls[skillNum].enable.Value = 1) {
        key := skillControls[skillNum].key.Value
        if key != "" {
            ; 只在勾选了维持BUFF时检查技能是否已激活
            if (skillNum <= 4 && skillBuffControls.Has(skillNum) && skillBuffControls[skillNum].Value = 1) {
                if skillPositions.Has(skillNum) {
                    pos := skillPositions[skillNum]
                    try {
                        skillActiveState := IsSkillActive(pos.x, pos.y)
                        
                        ; 只有在技能未激活时才发送按键
                        if (skillActiveState) {
                            return  ; 如果技能已激活，直接返回
                        }
                    } catch as err {
                        DebugLog("检测技能状态出错: " err.Message)
                    }
                }
            }
            
            if (shiftEnabled) {
                Send "{Shift down}"
                Send "{" key "}"
                Send "{Shift up}"
            } else {
                Send "{" key "}"
            }
        }
    }
}

PressLeftClick() {
    if (isRunning && !isPaused && mouseControls.left.enable.Value = 1) {
        if (shiftEnabled) {
            Send "{Shift down}"
            Click
            Send "{Shift up}"
        } else {
            Click
        }
    }
}

PressRightClick() {
    if (isRunning && !isPaused && mouseControls.right.enable.Value = 1) {
        if (shiftEnabled) {
            Send "{Shift down}"
            Click "right"
            Send "{Shift up}"
        } else {
            Click "right"
        }
    }
}

; 卡移速功能
SendKeys() {
    Send "r"
    Sleep 10
    Send "{Space}"
    Sleep 500
    Send "r"
}

; 保存设置
SaveSettings(*) {
    ; 保存所有设置到配置文件
    settingsFile := A_ScriptDir "\settings.ini"
    
    ; 保存技能设置
    Loop 4 {
        IniWrite(skillControls[A_Index].key.Value, settingsFile, "Skills", "Skill" A_Index "Key")
        IniWrite(skillControls[A_Index].enable.Value, settingsFile, "Skills", "Skill" A_Index "Enable")
        IniWrite(skillControls[A_Index].interval.Value, settingsFile, "Skills", "Skill" A_Index "Interval")
        ; 保存维持BUFF设置
        IniWrite(skillBuffControls[A_Index].Value, settingsFile, "Skills", "Skill" A_Index "Buff")
    }
    
    ; 保存鼠标设置
    IniWrite(mouseControls.left.enable.Value, settingsFile, "Mouse", "LeftClickEnable")
    IniWrite(mouseControls.left.interval.Value, settingsFile, "Mouse", "LeftClickInterval")
    IniWrite(mouseControls.right.enable.Value, settingsFile, "Mouse", "RightClickEnable")
    IniWrite(mouseControls.right.interval.Value, settingsFile, "Mouse", "RightClickInterval")
    
    ; 保存功能键设置
    IniWrite(utilityControls.dodge.enable.Value, settingsFile, "Utility", "DodgeEnable")
    IniWrite(utilityControls.dodge.interval.Value, settingsFile, "Utility", "DodgeInterval")
    
    IniWrite(utilityControls.potion.key.Value, settingsFile, "Utility", "PotionKey")
    IniWrite(utilityControls.potion.enable.Value, settingsFile, "Utility", "PotionEnable")
    IniWrite(utilityControls.potion.interval.Value, settingsFile, "Utility", "PotionInterval")
    
    statusBar.Text := "设置已保存"
}

; 热键设置
#HotIf WinActive("ahk_class Diablo IV Main Window Class")

F1::ToggleMacro()
F3::SendKeys()

Tab::{
    global isRunning, isPaused
    if !isRunning {
        Send "{Tab}"
        return
    }
    
    Send "{Tab}"
    isPaused := !isPaused
    
    if isPaused {
        StopAllTimers()
        statusText.Value := "状态: 已暂停"
        statusBar.Text := "宏已暂停"
    } else {
        StartAllTimers()
        statusText.Value := "状态: 运行中"
        statusBar.Text := "宏已继续"
    }
}

; 宏切换功能
ToggleMacro(*) {
    global isRunning, isPaused
    
    ; 确保完全停止所有定时器
    StopAllTimers()
    
    ; 切换运行状态
    isRunning := !isRunning
    
    if isRunning {
        ; 重置暂停状态
        isPaused := false
        previouslyPaused := false
        
        ; 只有在暗黑4窗口激活时才启动定时器
        if WinActive("ahk_class Diablo IV Main Window Class") {
            StartAllTimers()
            statusText.Value := "状态: 运行中"
            statusBar.Text := "宏已启动"
        } else {
            isPaused := true
            statusText.Value := "状态: 已暂停(窗口切换)"
            statusBar.Text := "宏已暂停 - 窗口未激活"
        }
    } else {
        ; 确保重置所有状态
        isPaused := false
        previouslyPaused := false
        statusText.Value := "状态: 已停止"
        statusBar.Text := "宏已停止"
        
        ; 确保释放所有按键
        ReleaseAllKeys()
    }
    
    DebugLog("ToggleMacro 状态: " . (isRunning ? "运行" : "停止"))
}

; 添加一个释放所有按键的函数
ReleaseAllKeys() {
    ; 确保释放所有可能被按住的按键
    Send "{Shift up}"  ; 释放Shift键
    Send "{Ctrl up}"   ; 释放Ctrl键
    Send "{Alt up}"    ; 释放Alt键
    
    ; 释放1-4号技能键
    Loop 4 {
        key := skillControls[A_Index].key.Value
        if key != ""
            Send "{" key " up}"
    }
    
    ; 释放鼠标按键
    SetMouseDelay -1
    Click "up left"    ; 修正：使用正确的语法释放左键
    Click "up right"   ; 修正：使用正确的语法释放右键
    
    DebugLog("已释放所有按键")
}

; 设置窗口状态检查定时器
SetTimer CheckWindow, 100

; 退出处理
myGui.OnEvent("Close", (*) => ExitApp())
myGui.OnEvent("Escape", (*) => ExitApp())

; 加载设置函数
LoadSettings() {
    settingsFile := A_ScriptDir "\settings.ini"
    
    if !FileExist(settingsFile)
        return
    
    ; 加载技能设置
    Loop 4 {
        try {
            key := IniRead(settingsFile, "Skills", "Skill" A_Index "Key", A_Index)
            enabled := IniRead(settingsFile, "Skills", "Skill" A_Index "Enable", 1)
            interval := IniRead(settingsFile, "Skills", "Skill" A_Index "Interval", 300)
            ; 加载维持BUFF设置
            buffEnabled := IniRead(settingsFile, "Skills", "Skill" A_Index "Buff", 0)
            
            skillControls[A_Index].key.Value := key
            skillControls[A_Index].enable.Value := enabled
            skillControls[A_Index].interval.Value := interval
            skillBuffControls[A_Index].Value := buffEnabled
        }
    }
    
    ; 加载鼠标设置
    try {
        mouseControls.left.enable.Value := IniRead(settingsFile, "Mouse", "LeftClickEnable", 1)
        mouseControls.left.interval.Value := IniRead(settingsFile, "Mouse", "LeftClickInterval", 80)
        mouseControls.right.enable.Value := IniRead(settingsFile, "Mouse", "RightClickEnable", 0)
        mouseControls.right.interval.Value := IniRead(settingsFile, "Mouse", "RightClickInterval", 300)
    }
    
    ; 加载功能键设置
    try {
        utilityControls.dodge.enable.Value := IniRead(settingsFile, "Utility", "DodgeEnable", 0)
        utilityControls.dodge.interval.Value := IniRead(settingsFile, "Utility", "DodgeInterval", 1000)
        
        utilityControls.potion.key.Value := IniRead(settingsFile, "Utility", "PotionKey", "q")
        utilityControls.potion.enable.Value := IniRead(settingsFile, "Utility", "PotionEnable", 0)
        utilityControls.potion.interval.Value := IniRead(settingsFile, "Utility", "PotionInterval", 15000)
    }
}

; 切换Shift键勾选框
ToggleShift(*) {
    global shiftEnabled
    shiftEnabled := !shiftEnabled
}

; 添加功能键按键函数
PressDodge() {
    if (isRunning && !isPaused && utilityControls.dodge.enable.Value = 1) {
        if (shiftEnabled) {
            Send "{Shift down}"
            Sleep 10
            Send "{Space}"
            Sleep 10
            Send "{Shift up}"
        } else {
            Send "{Space}"
        }
    }
}

PressPotion() {
    if (isRunning && !isPaused && utilityControls.potion.enable.Value = 1) {
        key := utilityControls.potion.key.Value
        if key != "" {
            if (shiftEnabled) {
                Send "{Shift down}"
                Sleep 10
                Send "{" key "}"
                Sleep 10
                Send "{Shift up}"
            } else {
                Send "{" key "}"
            }
        }
    }
}

; 添加检测技能激活状态的函数
IsSkillActive(x, y) {
    ; 获取指定坐标的像素颜色
    color := PixelGetColor(x, y)
    
    ; 提取绿色分量 (中间两位十六进制)
    green := (color >> 8) & 0xFF
    
    ; 判断绿色分量是否大于60
    return green > 60
} 
