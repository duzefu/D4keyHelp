#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority "High"

; ========== 全局变量定义 ==========
; 核心状态变量
global DEBUG := true
global debugLogFile := A_ScriptDir "\debugd4.log"
global isRunning := false
global isPaused := false
global previouslyPaused := false
global counter := 0

; GUI相关变量
global myGui := ""
global statusText := ""
global statusBar := ""
global skillControls := Map()
global skillBuffControls := Map()
global mouseControls := {}
global utilityControls := {}

; 功能状态变量
global shiftEnabled := false
global skillActiveState := false
global mouseAutoMoveEnabled := false
global mouseAutoMoveCurrentPoint := 1

; 技能位置映射
global skillPositions := Map(
    1, {x: 1035, y: 1290},
    2, {x: 1035 + 84, y: 1290},
    3, {x: 1035 + 84 * 2, y: 1290},
    4, {x: 1035 + 84 * 3, y: 1290},
    "left", {x: 1035 + 84 * 4, y: 1290},
    "right", {x: 1035 + 84 * 5, y: 1290}
)

; 定时器相关变量
global boundSkillTimers := Map()  ; 存储绑定的技能定时器函数
global timerStates := Map()       ; 用于跟踪定时器状态

; 控件变量
global forceMove := {}            ; 强制移动控件
global mouseAutoMove := {}        ; 鼠标自动移动控件

; ========== 辅助函数 ==========
/**
 * 调试日志记录函数
 * @param {String} message - 要记录的消息
 */
DebugLog(message) {
    if DEBUG {
        try {
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            FileAppend timestamp " - " message "`n", debugLogFile
        } catch as err {
            ; 如果日志写入失败，不要让程序崩溃
            OutputDebug "日志写入失败: " err.Message
        }
    }
}

; ========== GUI创建 ==========
/**
 * 创建主GUI界面
 */
CreateMainGUI() {
    global myGui, statusText, statusBar

    ; 创建主窗口
    myGui := Gui("", "暗黑4助手 v2.1")
    myGui.BackColor := "FFFFFF"
    myGui.SetFont("s10", "Microsoft YaHei UI")

    ; 添加主要内容区域
    myGui.AddGroupBox("x10 y10 w460 h120", "状态")
    statusText := myGui.AddText("x30 y35 w200 h20", "状态: 未运行")
    myGui.AddButton("x30 y65 w120 h30", "开始/停止(F1)").OnEvent("Click", ToggleMacro)
    myGui.AddText("x170 y70 w200 h20", "F3: 卡移速")
    myGui.AddText("x30 y100 w300 h20", "提示：仅在暗黑破坏神4窗口活动时生效")

    ; 添加技能设置区域
    myGui.AddGroupBox("x10 y140 w460 h350", "键设置")

    ; 添加Shift键勾选框
    myGui.AddCheckbox("x30 y165 w100 h20", "按住Shift").OnEvent("Click", ToggleShift)

    ; 添加列标题
    myGui.AddText("x30 y195 w60 h20", "按键")
    myGui.AddText("x130 y195 w60 h20", "启用")
    myGui.AddText("x200 y195 w120 h20", "间隔(毫秒)")
}

/**
 * 创建技能控件
 */
CreateSkillControls() {
    global myGui, skillControls, skillBuffControls

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
}

/**
 * 创建鼠标控件
 */
CreateMouseControls() {
    global myGui, mouseControls

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
}

/**
 * 创建功能键控件
 */
CreateUtilityControls() {
    global myGui, utilityControls, mouseAutoMove

    myGui.AddText("x30 y405 w60 h20", "翻滚:")
    myGui.AddText("x30 y435 w60 h20", "喝药:")
    myGui.AddText("x30 y465 w60 h20", "强移:")

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
        },
        forceMove: {
            key: myGui.AddHotkey("x90 y465 w35 h20", "``"),
            enable: myGui.AddCheckbox("x130 y465 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y465 w60 h20", "50")
        }
    }

    ; 添加鼠标自动移动控件
    mouseAutoMove := {
        enable: myGui.AddCheckbox("x290 y465 w140 h20", "鼠标自动移动"),
        interval: myGui.AddEdit("x430 y465 w40 h20", "1000")
    }
    mouseAutoMove.enable.OnEvent("Click", ToggleMouseAutoMove)
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar

    ; 创建主GUI
    CreateMainGUI()

    ; 创建各种控件
    CreateSkillControls()
    CreateMouseControls()
    CreateUtilityControls()

    ; 添加保存按钮
    myGui.AddButton("x30 y500 w100 h30", "保存设置").OnEvent("Click", SaveSettings)

    ; 添加状态栏
    statusBar := myGui.AddStatusBar(, "就绪")

    ; 显示GUI
    myGui.Show("w480 h550")

    ; 加载设置
    LoadSettings()

    ; 设置窗口事件处理
    myGui.OnEvent("Close", (*) => ExitApp())
    myGui.OnEvent("Escape", (*) => ExitApp())
}

; 初始化GUI
InitializeGUI()

; ========== 窗口管理 ==========
/**
 * 窗口切换检查函数
 * 检测暗黑4窗口是否激活，并在状态变化时触发相应事件
 */
CheckWindow() {
    static lastState := false
    currentState := WinActive("ahk_class Diablo IV Main Window Class")

    if (currentState != lastState) {
        OnWindowChange(currentState)
        lastState := currentState
    }
}

/**
 * 窗口切换事件处理
 * @param {Boolean} isActive - 暗黑4窗口是否激活
 */
OnWindowChange(isActive) {
    global isRunning, isPaused, previouslyPaused, statusText, statusBar

    if (!isActive) {  ; 窗口失去焦点
        if (isRunning) {
            previouslyPaused := isPaused
            if (!isPaused) {
                StopAllTimers()
                isPaused := true
                UpdateStatus("已暂停(窗口切换)", "宏已暂停 - 窗口未激活")
            }
        }
    } else if (isRunning && isPaused && !previouslyPaused) {  ; 窗口获得焦点且之前不是手动暂停
        StartAllTimers()
        isPaused := false
        UpdateStatus("运行中", "宏已恢复 - 窗口已激活")
    }
}

/**
 * 更新状态显示
 * @param {String} status - 主状态文本
 * @param {String} barText - 状态栏文本
 */
UpdateStatus(status, barText) {
    global statusText, statusBar
    statusText.Value := "状态: " status
    statusBar.Text := barText
    DebugLog("状态更新: " status " | " barText)
}

; ========== 定时器管理 ==========
/**
 * 启动所有定时器
 */
StartAllTimers() {
    ; 先停止所有定时器，确保清理
    StopAllTimers()

    ; 启动技能定时器
    StartSkillTimers()

    ; 启动鼠标和功能键定时器
    StartUtilityTimers()

    ; 启动鼠标自动移动定时器
    StartMouseAutoMoveTimer()

    DebugLog("所有定时器已启动")
}

/**
 * 启动技能定时器
 */
StartSkillTimers() {
    global skillControls, boundSkillTimers, timerStates

    for i in [1, 2, 3, 4] {
        if (skillControls[i].enable.Value = 1) {
            interval := Integer(skillControls[i].interval.Value)
            if (interval > 0) {
                boundSkillTimers[i] := PressSkill.Bind(i)
                SetTimer(boundSkillTimers[i], interval)
                timerStates[i] := true
                DebugLog("启动技能" i "定时器，间隔: " interval)
            }
        }
    }
}

/**
 * 启动鼠标和功能键定时器
 */
StartUtilityTimers() {
    StartSingleTimer("leftClick", mouseControls.left, PressLeftClick)
    StartSingleTimer("rightClick", mouseControls.right, PressRightClick)
    StartSingleTimer("dodge", utilityControls.dodge, PressDodge)
    StartSingleTimer("potion", utilityControls.potion, PressPotion)
    StartSingleTimer("forceMove", utilityControls.forceMove, PressForceMove)
}

/**
 * 启动鼠标自动移动定时器
 */
StartMouseAutoMoveTimer() {
    global mouseAutoMoveEnabled, mouseAutoMove, timerStates

    DebugLog("鼠标自动移动状态: " . (mouseAutoMoveEnabled ? "启用" : "禁用") . ", GUI勾选状态: " . mouseAutoMove.enable.Value)

    if (mouseAutoMoveEnabled) {
        interval := Integer(mouseAutoMove.interval.Value)
        if (interval > 0) {
            SetTimer(MoveMouseToNextPoint, interval)
            timerStates["mouseAutoMove"] := true
            DebugLog("启动鼠标自动移动定时器 - 间隔: " interval)
        }
    }
}

/**
 * 启动单个定时器
 * @param {String} name - 定时器名称
 * @param {Object} control - 控件对象
 * @param {Function} timerFunc - 定时器函数
 */
StartSingleTimer(name, control, timerFunc) {
    global timerStates

    if (control.enable.Value = 1) {
        interval := Integer(control.interval.Value)
        if (interval > 0) {
            SetTimer(timerFunc, interval)
            timerStates[name] := true
            DebugLog("启动" name "定时器 - 间隔: " interval)
        }
    }
}

/**
 * 停止所有定时器
 */
StopAllTimers() {
    global boundSkillTimers

    ; 停止技能定时器
    Loop 4 {
        if boundSkillTimers.Has(A_Index) {
            SetTimer(boundSkillTimers[A_Index], 0)
            boundSkillTimers.Delete(A_Index)
            DebugLog("停止技能" A_Index "定时器")
        }
    }

    ; 停止所有其他定时器
    SetTimer PressLeftClick, 0
    SetTimer PressRightClick, 0
    SetTimer PressDodge, 0
    SetTimer PressPotion, 0
    SetTimer PressForceMove, 0
    SetTimer MoveMouseToNextPoint, 0

    DebugLog("已停止所有定时器")
}

; ========== 按键功能实现 ==========
/**
 * 按下技能键
 * @param {Integer} skillNum - 技能编号(1-4)
 */
PressSkill(skillNum) {
    global isRunning, isPaused, skillControls, skillBuffControls, skillPositions

    ; 检查基本条件
    if (!isRunning || isPaused || !skillControls[skillNum].enable.Value)
        return

    ; 获取按键
    key := skillControls[skillNum].key.Value
    if (key = "")
        return

    ; 检查BUFF状态
    if (skillNum <= 4 && skillBuffControls[skillNum].Value = 1) {
        try {
            if (skillPositions.Has(skillNum)) {
                pos := skillPositions[skillNum]
                if (IsSkillActive(pos.x, pos.y)) {
                    DebugLog("技能" skillNum "已激活，跳过")
                    return
                }
            }
        } catch as err {
            DebugLog("检测技能状态出错: " err.Message)
        }
    }

    ; 发送按键
    SendKey(key)
    DebugLog("按下技能" skillNum " 键: " key)
}

/**
 * 统一的按键发送函数
 * @param {String} key - 要发送的按键
 */
SendKey(key) {
    global shiftEnabled

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

/**
 * 鼠标左键点击
 */
PressLeftClick() {
    global isRunning, isPaused, mouseControls, shiftEnabled

    if (isRunning && !isPaused && mouseControls.left.enable.Value) {
        if (shiftEnabled) {
            Send "{Shift down}"
            Sleep 10
            Click
            Sleep 10
            Send "{Shift up}"
        } else {
            Click
        }
    }
}

/**
 * 鼠标右键点击
 */
PressRightClick() {
    global isRunning, isPaused, mouseControls, shiftEnabled

    if (isRunning && !isPaused && mouseControls.right.enable.Value = 1) {
        if (shiftEnabled) {
            Send "{Shift down}"
            Sleep 10
            Click "right"
            Sleep 10
            Send "{Shift up}"
        } else {
            Click "right"
        }
    }
}

/**
 * 卡移速功能
 * 按下r键、空格键，然后再按r键
 */
SendKeys() {
    Send "r"
    Sleep 10
    Send "{Space}"
    Sleep 500
    Send "r"
    DebugLog("执行卡移速")
}

; ========== 设置管理 ==========
/**
 * 保存设置到INI文件
 */
SaveSettings(*) {
    global statusBar
    settingsFile := A_ScriptDir "\settings.ini"

    try {
        ; 保存各类设置
        SaveSkillSettings(settingsFile)
        SaveMouseSettings(settingsFile)
        SaveUtilitySettings(settingsFile)

        statusBar.Text := "设置已保存"
        DebugLog("所有设置已保存到: " settingsFile)
    } catch as err {
        statusBar.Text := "保存设置失败: " err.Message
        DebugLog("保存设置失败: " err.Message)
    }
}

/**
 * 保存技能设置
 * @param {String} file - 设置文件路径
 */
SaveSkillSettings(file) {
    global skillControls, skillBuffControls
    section := "Skills"

    for i in [1, 2, 3, 4] {
        IniWrite(skillControls[i].key.Value, file, section, "Skill" i "Key")
        IniWrite(skillControls[i].enable.Value, file, section, "Skill" i "Enable")
        IniWrite(skillControls[i].interval.Value, file, section, "Skill" i "Interval")
        IniWrite(skillBuffControls[i].Value, file, section, "Skill" i "Buff")
    }
}

/**
 * 保存鼠标设置
 * @param {String} file - 设置文件路径
 */
SaveMouseSettings(file) {
    global mouseControls, mouseAutoMove
    section := "Mouse"

    IniWrite(mouseControls.left.enable.Value, file, section, "LeftClickEnable")
    IniWrite(mouseControls.left.interval.Value, file, section, "LeftClickInterval")
    IniWrite(mouseControls.right.enable.Value, file, section, "RightClickEnable")
    IniWrite(mouseControls.right.interval.Value, file, section, "RightClickInterval")
    IniWrite(mouseAutoMove.enable.Value, file, section, "MouseAutoMoveEnable")
    IniWrite(mouseAutoMove.interval.Value, file, section, "MouseAutoMoveInterval")
}

/**
 * 保存功能键设置
 * @param {String} file - 设置文件路径
 */
SaveUtilitySettings(file) {
    global utilityControls
    section := "Utility"

    IniWrite(utilityControls.dodge.enable.Value, file, section, "DodgeEnable")
    IniWrite(utilityControls.dodge.interval.Value, file, section, "DodgeInterval")
    IniWrite(utilityControls.potion.key.Value, file, section, "PotionKey")
    IniWrite(utilityControls.potion.enable.Value, file, section, "PotionEnable")
    IniWrite(utilityControls.potion.interval.Value, file, section, "PotionInterval")
    IniWrite(utilityControls.forceMove.key.Value, file, section, "ForceMoveKey")
    IniWrite(utilityControls.forceMove.enable.Value, file, section, "ForceMoveEnable")
    IniWrite(utilityControls.forceMove.interval.Value, file, section, "ForceMoveInterval")
}

/**
 * 加载设置函数
 */
LoadSettings() {
    settingsFile := A_ScriptDir "\settings.ini"

    if !FileExist(settingsFile) {
        DebugLog("设置文件不存在，使用默认设置")
        return
    }

    try {
        ; 加载各类设置
        LoadSkillSettings(settingsFile)
        LoadMouseSettings(settingsFile)
        LoadUtilitySettings(settingsFile)

        DebugLog("所有设置已从文件加载: " settingsFile)
    } catch as err {
        DebugLog("加载设置出错: " err.Message)
    }
}

/**
 * 加载技能设置
 * @param {String} file - 设置文件路径
 */
LoadSkillSettings(file) {
    global skillControls, skillBuffControls

    Loop 4 {
        try {
            key := IniRead(file, "Skills", "Skill" A_Index "Key", A_Index)
            enabled := IniRead(file, "Skills", "Skill" A_Index "Enable", 1)
            interval := IniRead(file, "Skills", "Skill" A_Index "Interval", 300)
            buffEnabled := IniRead(file, "Skills", "Skill" A_Index "Buff", 0)

            skillControls[A_Index].key.Value := key
            skillControls[A_Index].enable.Value := enabled
            skillControls[A_Index].interval.Value := interval
            skillBuffControls[A_Index].Value := buffEnabled
        } catch as err {
            DebugLog("加载技能" A_Index "设置出错: " err.Message)
        }
    }
}

/**
 * 加载鼠标设置
 * @param {String} file - 设置文件路径
 */
LoadMouseSettings(file) {
    global mouseControls, mouseAutoMove, mouseAutoMoveEnabled

    try {
        mouseControls.left.enable.Value := IniRead(file, "Mouse", "LeftClickEnable", 1)
        mouseControls.left.interval.Value := IniRead(file, "Mouse", "LeftClickInterval", 80)
        mouseControls.right.enable.Value := IniRead(file, "Mouse", "RightClickEnable", 0)
        mouseControls.right.interval.Value := IniRead(file, "Mouse", "RightClickInterval", 300)
        mouseAutoMove.enable.Value := IniRead(file, "Mouse", "MouseAutoMoveEnable", 0)
        mouseAutoMove.interval.Value := IniRead(file, "Mouse", "MouseAutoMoveInterval", 1000)
        mouseAutoMoveEnabled := (mouseAutoMove.enable.Value = 1)

        DebugLog("加载鼠标设置 - 自动移动状态: " . (mouseAutoMoveEnabled ? "启用" : "禁用"))
    } catch as err {
        DebugLog("加载鼠标设置出错: " err.Message)
    }
}

/**
 * 加载功能键设置
 * @param {String} file - 设置文件路径
 */
LoadUtilitySettings(file) {
    global utilityControls

    try {
        utilityControls.dodge.enable.Value := IniRead(file, "Utility", "DodgeEnable", 0)
        utilityControls.dodge.interval.Value := IniRead(file, "Utility", "DodgeInterval", 1000)

        utilityControls.potion.key.Value := IniRead(file, "Utility", "PotionKey", "q")
        utilityControls.potion.enable.Value := IniRead(file, "Utility", "PotionEnable", 0)
        utilityControls.potion.interval.Value := IniRead(file, "Utility", "PotionInterval", 15000)

        utilityControls.forceMove.key.Value := IniRead(file, "Utility", "ForceMoveKey", "``")
        utilityControls.forceMove.enable.Value := IniRead(file, "Utility", "ForceMoveEnable", 0)
        utilityControls.forceMove.interval.Value := IniRead(file, "Utility", "ForceMoveInterval", 50)
    } catch as err {
        DebugLog("加载功能键设置出错: " err.Message)
    }
}

; ========== 宏控制功能 ==========
/**
 * 切换宏运行状态
 */
ToggleMacro(*) {
    global isRunning, isPaused, previouslyPaused, mouseAutoMoveEnabled, mouseAutoMove

    ; 确保完全停止所有定时器
    StopAllTimers()

    ; 切换运行状态
    isRunning := !isRunning

    if isRunning {
        ; 重置暂停状态
        isPaused := false
        previouslyPaused := false

        ; 确保鼠标自动移动状态与GUI勾选框一致
        mouseAutoMoveEnabled := (mouseAutoMove.enable.Value = 1)

        ; 只有在暗黑4窗口激活时才启动定时器
        if WinActive("ahk_class Diablo IV Main Window Class") {
            StartAllTimers()
            UpdateStatus("运行中", "宏已启动")
        } else {
            isPaused := true
            UpdateStatus("已暂停(窗口切换)", "宏已暂停 - 窗口未激活")
        }
    } else {
        ; 确保重置所有状态
        isPaused := false
        previouslyPaused := false
        UpdateStatus("已停止", "宏已停止")

        ; 确保释放所有按键
        ReleaseAllKeys()
    }

    DebugLog("宏状态切换: " . (isRunning ? "运行" : "停止"))
}

/**
 * 释放所有可能被按住的按键
 */
ReleaseAllKeys() {
    global skillControls

    ; 释放修饰键
    Send "{Shift up}"
    Send "{Ctrl up}"
    Send "{Alt up}"

    ; 释放技能键
    Loop 4 {
        key := skillControls[A_Index].key.Value
        if key != ""
            Send "{" key " up}"
    }

    ; 释放鼠标按键
    SetMouseDelay -1
    Click "up left"
    Click "up right"

    DebugLog("已释放所有按键")
}

/**
 * 切换Shift键状态
 */
ToggleShift(*) {
    global shiftEnabled
    shiftEnabled := !shiftEnabled
    DebugLog("Shift键状态: " . (shiftEnabled ? "启用" : "禁用"))
}

/**
 * 切换鼠标自动移动功能
 */
ToggleMouseAutoMove(*) {
    global mouseAutoMoveEnabled, mouseAutoMove, isRunning, isPaused, timerStates

    mouseAutoMoveEnabled := !mouseAutoMoveEnabled

    ; 更新GUI勾选框状态以匹配当前状态
    mouseAutoMove.enable.Value := mouseAutoMoveEnabled ? 1 : 0

    ; 如果宏已经在运行，则更新定时器状态
    if (isRunning && !isPaused) {
        if (mouseAutoMoveEnabled) {
            interval := Integer(mouseAutoMove.interval.Value)
            if (interval > 0) {
                SetTimer(MoveMouseToNextPoint, interval)
                timerStates["mouseAutoMove"] := true
                DebugLog("启动鼠标自动移动定时器 - 间隔: " interval)
            }
        } else {
            SetTimer(MoveMouseToNextPoint, 0)
            timerStates["mouseAutoMove"] := false
            DebugLog("停止鼠标自动移动定时器")
        }
    }

    DebugLog("鼠标自动移动状态切换: " . (mouseAutoMoveEnabled ? "启用" : "禁用"))
}

; ========== 热键设置 ==========
#HotIf WinActive("ahk_class Diablo IV Main Window Class")

*F1::ToggleMacro()  ; * 表示忽略所有修饰键
F3::SendKeys()

Tab::{
    global isRunning, isPaused

    ; 发送原始Tab键
    Send "{Tab}"

    ; 如果宏未运行，不做其他处理
    if !isRunning
        return

    ; 切换暂停状态
    isPaused := !isPaused

    if isPaused {
        StopAllTimers()
        UpdateStatus("已暂停", "宏已暂停")
    } else {
        StartAllTimers()
        UpdateStatus("运行中", "宏已继续")
    }
}

; 设置窗口状态检查定时器
SetTimer CheckWindow, 100

; ========== 功能键实现 ==========
/**
 * 按下翻滚键(空格)
 */
PressDodge() {
    global isRunning, isPaused, utilityControls, shiftEnabled

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
        DebugLog("按下翻滚键")
    }
}

/**
 * 按下喝药键
 */
PressPotion() {
    global isRunning, isPaused, utilityControls, shiftEnabled

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
            DebugLog("按下喝药键: " key)
        }
    }
}

/**
 * 按下强制移动键
 */
PressForceMove() {
    global isRunning, isPaused, utilityControls, shiftEnabled

    if (isRunning && !isPaused && utilityControls.forceMove.enable.Value = 1) {
        key := utilityControls.forceMove.key.Value
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
            DebugLog("按下强制移动键: " key)
        }
    }
}

/**
 * 检测技能激活状态
 * @param {Integer} x - 检测点X坐标
 * @param {Integer} y - 检测点Y坐标
 * @returns {Boolean} - 技能是否激活
 */
IsSkillActive(x, y) {
    try {
        ; 获取指定坐标的像素颜色
        color := PixelGetColor(x, y)

        ; 提取绿色分量 (中间两位十六进制)
        green := (color >> 8) & 0xFF

        ; 判断绿色分量是否大于60
        return green > 60
    } catch as err {
        DebugLog("检测技能状态失败: " err.Message)
        return false
    }
}

/**
 * 鼠标自动移动函数
 */
MoveMouseToNextPoint() {
    global mouseAutoMoveCurrentPoint, isRunning, isPaused, mouseAutoMoveEnabled

    if (!isRunning || isPaused || !mouseAutoMoveEnabled)
        return

    try {
        ; 获取屏幕分辨率
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight

        ; 计算六个点的位置
        points := [
            {x: screenWidth * 0.15, y: screenHeight * 0.15},  ; 左上角
            {x: screenWidth * 0.5, y: screenHeight * 0.15},   ; 中上角
            {x: screenWidth * 0.85, y: screenHeight * 0.15},  ; 右上角
            {x: screenWidth * 0.85, y: screenHeight * 0.85},  ; 右下角
            {x: screenWidth * 0.5, y: screenHeight * 0.85},   ; 中下角
            {x: screenWidth * 0.15, y: screenHeight * 0.85}   ; 左下角
        ]

        ; 移动鼠标到当前点
        currentPoint := points[mouseAutoMoveCurrentPoint]
        MouseMove(currentPoint.x, currentPoint.y, 0)

        ; 更新到下一个点
        mouseAutoMoveCurrentPoint := Mod(mouseAutoMoveCurrentPoint, 6) + 1

        DebugLog("鼠标自动移动到点" mouseAutoMoveCurrentPoint ": x=" currentPoint.x ", y=" currentPoint.y)
    } catch as err {
        DebugLog("鼠标自动移动失败: " err.Message)
    }
}
