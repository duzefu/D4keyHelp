#Requires AutoHotkey v2.0
#SingleInstance Force
ProcessSetPriority "High"

; ========== 全局变量定义 ==========
; 核心状态变量
global DEBUG := false ; 是否启用调试模式
global debugLogFile := A_ScriptDir "\debugd4.log"
global isRunning := false
global isPaused := false
global previouslyPaused := false
global counter := 0
global D4W := 0 ; Diablo IV 窗口宽度
global D4H := 0 ; Diablo IV 窗口高度
;global D4helpkey := ""

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

; 技能模式常量
global SKILL_MODE_CLICK := 1    ; 连点模式
global SKILL_MODE_BUFF := 2     ; BUFF模式
global SKILL_MODE_HOLD := 3     ; 按住模式
global skillModeNames := ["连点", "BUFF", "按住"]

; 技能位置映射
global skillPositions := Map()


; 定时器相关变量
global boundSkillTimers := Map()  ; 存储绑定的技能定时器函数
global timerStates := Map()       ; 用于跟踪定时器状态

; 控件变量
global forceMove := {}            ; 强制移动控件
global mouseAutoMove := {}        ; 鼠标自动移动控件
/**
 * 获取 Diablo IV 窗口的分辨率
 */

GetDiabloIVResolution() {
    global D4W, D4H
    ; 获取 Diablo IV 窗口的位置和大小
    if WinExist("ahk_class Diablo IV Main Window Class") {
        WinGetPos(, , &D4W, &D4H, "ahk_class Diablo IV Main Window Class")
    }
}
/**
 * 动态计算技能位置
 * 基于窗口分辨率 D4W 和 D4H
 */
GetDynamicSkillPositions() {
    global D4W, D4H, skillPositions

    ; 基准分辨率
    baseWidth := 3840
    baseHeight := 2160

    ; 比例因子，采用较小的缩放因子以保证纵横比不变
    scale := Min(D4W / baseWidth, D4H / baseHeight)

    ; 技能条基准起点和间距
    baseX := 1550
    baseY := 1940
    offset := 127

    ; 动态计算技能位置
    skillPositions := Map()
    Loop 5 {
        idx := A_Index
        skillPositions[idx] := {
            x: Round((baseX + offset * (idx - 1)) * scale),
            y: Round(baseY * scale)
        }
    }
    ; 左键和右键位置
    skillPositions["left"] := {
        x: Round((baseX + offset * 4) * scale),
        y: Round(baseY * scale)
    }
    skillPositions["right"] := {
        x: Round((baseX + offset * 5) * scale),
        y: Round(baseY * scale)
    }
}
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
    myGui.AddButton("x30 y65 w80 h30", "开始/停止").OnEvent("Click", ToggleMacro)
    myGui.AddText("x220 y70 w200 h20", "F3: 卡快照")
    myGui.AddText("x30 y100 w300 h20", "提示：仅在暗黑破坏神4窗口活动时生效")
    ; 添加技能设置区域
    myGui.AddGroupBox("x10 y140 w460 h410", "键设置")

    ; 添加Shift键勾选框
    myGui.AddCheckbox("x30 y165 w100 h20", "按住Shift").OnEvent("Click", ToggleShift)

    ; 添加列标题
    myGui.AddText("x30 y195 w60 h20", "按键")
    myGui.AddText("x130 y195 w60 h20", "启用")
    myGui.AddText("x200 y195 w120 h20", "间隔(毫秒)")


    ;myGui.AddHotkey("x120 y70 w80 h20","f1") ; 热键输入框
 
}

/**
 * 创建技能控件
 */
CreateSkillControls() {
    global myGui, skillControls, skillModeNames, SKILL_MODE_CLICK

    skillControls := Map()
    Loop 5 {
        yPos := 225 + (A_Index-1) * 30
        myGui.AddText("x30 y" yPos " w60 h20", "技能" A_Index ":")
        skillControls[A_Index] := {
            key: myGui.AddHotkey("x90 y" yPos " w35 h20", A_Index),
            enable: myGui.AddCheckbox("x130 y" yPos " w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y" yPos " w60 h20", "20"),
            mode: myGui.AddDropDownList("x270 y" yPos " w100 h120 Choose1", skillModeNames)
        }
    }
}

/**
 * 创建鼠标控件
 */
CreateMouseControls() {
    global myGui, mouseControls, skillModeNames, SKILL_MODE_CLICK

    mouseControls := {
        left: {
            enable: myGui.AddCheckbox("x130 y375 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y375 w60 h20", "80"),
            mode: myGui.AddDropDownList("x270 y375 w100 h120 Choose1", skillModeNames)
        },
        right: {
            enable: myGui.AddCheckbox("x130 y405 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y405 w60 h20", "300"),
            mode: myGui.AddDropDownList("x270 y405 w100 h120 Choose1", skillModeNames)
        }
    }
    myGui.AddText("x30 y375 w60 h20", "左键:")
    myGui.AddText("x30 y405 w60 h20", "右键:")
}

/**
 * 创建功能键控件
 */
CreateUtilityControls() {
    global myGui, utilityControls, mouseAutoMove

    myGui.AddText("x30 y435 w60 h20", "翻滚:")
    myGui.AddText("x30 y465 w60 h20", "喝药:")
    myGui.AddText("x30 y495 w60 h20", "强移:")
    myGui.AddText("x30 y560 w60 h20", "火盾:")
    myGui.AddText("x110 y560 w60 h20", "电矛:")
    myGui.AddText("x190 y560 w60 h20", "电球:")
    myGui.AddText("x280 y560 w60 h20", "冰盾:")

    utilityControls := {
        dodge: {
            key: myGui.AddText("x90 y435 w35 h20", "空格"),
            enable: myGui.AddCheckbox("x130 y435 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y435 w60 h20", "20")
        },
        potion: {
            key: myGui.AddHotkey("x90 y465 w35 h20", "q"),
            enable: myGui.AddCheckbox("x130 y465 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y465 w60 h20", "3000")
        },
        forceMove: {
            key: myGui.AddHotkey("x90 y495 w35 h20", "``"),
            enable: myGui.AddCheckbox("x130 y495 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y495 w60 h20", "50")
        },
        huoDun: {  ; 火盾
            key: myGui.AddHotkey("x70 y555 w35 h20", "2"),
        },    
        dianMao: {  ; 电矛
            key: myGui.AddHotkey("x150 y555 w35 h20", "1"),
        },
        dianQiu: {  ; 电球
            key: myGui.AddHotkey("x230 y555 w35 h20", "e"),
        },
        binDun: {  ; 冰盾
            key: myGui.AddHotkey("x320 y555 w35 h20", "3"),
        }
    }

    ; 添加鼠标自动移动控件
    mouseAutoMove := {
        enable: myGui.AddCheckbox("x30 y525 w100 h20", "鼠标自动移动"),
        interval: myGui.AddEdit("x160 y525 w40 h20", "1000")
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
    myGui.AddButton("x30 y590 w100 h30", "保存设置").OnEvent("Click", SaveSettings)

    ; 添加状态栏
    statusBar := myGui.AddStatusBar(, "就绪")

    ; 显示GUI
    myGui.Show("w480 h660")

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

    for i in [1, 2, 3, 4, 5] {
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
    global boundSkillTimers, skillControls

    ; 停止技能定时器
    Loop 5 {
        if boundSkillTimers.Has(A_Index) {
            SetTimer(boundSkillTimers[A_Index], 0)
            boundSkillTimers.Delete(A_Index)
            DebugLog("停止技能" A_Index "定时器")
        }

        ; 如果是按住模式，确保释放按键
        key := skillControls[A_Index].key.Value
        if (key != "") {
            Send "{" key " up}"
        }
    }

    ; 停止所有其他定时器
    SetTimer PressLeftClick, 0
    SetTimer PressRightClick, 0
    SetTimer PressDodge, 0
    SetTimer PressPotion, 0
    SetTimer PressForceMove, 0
    SetTimer MoveMouseToNextPoint, 0

    ; 重置所有按住模式的按键状态
    ResetAllHoldKeyStates()

    ; 重置鼠标按键状态
    ResetMouseButtonStates()

    DebugLog("已停止所有定时器并释放按键")
}

; ========== 按键功能实现 ==========
/**
 * 按下技能键
 * @param {Integer} skillNum - 技能编号(1-5)
 */
PressSkill(skillNum) {
    global isRunning, isPaused, skillControls, skillPositions
    global SKILL_MODE_CLICK, SKILL_MODE_BUFF, SKILL_MODE_HOLD

    ; 检查基本条件
    if (!isRunning || isPaused || !skillControls[skillNum].enable.Value)
        return

    ; 获取按键
    key := skillControls[skillNum].key.Value
    if (key = "")
        return

    ; 获取当前技能模式
    skillMode := skillControls[skillNum].mode.Value

    ; 根据不同模式处理
    if (skillMode == SKILL_MODE_BUFF) {
        ; 维持BUFF模式 - 检查技能是否已激活
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

        ; 发送按键
        SendKey(key)
        DebugLog("按下技能" skillNum " 键(维持BUFF模式): " key)
    }
    else if (skillMode == SKILL_MODE_HOLD) {
            Send "{" key " down}"
            DebugLog("按住技能" skillNum " 键: " key)
        }    
    else {
        ; 默认连点模式 - 直接发送按键
        SendKey(key)
        DebugLog("按下技能" skillNum " 键(连点模式): " key)
    }
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
    global SKILL_MODE_CLICK, SKILL_MODE_BUFF, SKILL_MODE_HOLD

    if (!isRunning || isPaused || !mouseControls.left.enable.Value)
        return

    ; 获取当前模式
    mouseMode := mouseControls.left.mode.Value

    ; 按住模式处理
    if (mouseMode == SKILL_MODE_HOLD) {
        static leftMouseHeld := false

        if (!leftMouseHeld) {
            if (shiftEnabled)
                Send "{Shift down}"

            Click "down left"
            leftMouseHeld := true
            DebugLog("按住鼠标左键")
        }
    }
    ; 连点模式处理
    else {
        if (shiftEnabled) {
            Send "{Shift down}"
            Sleep 10
            Click
            Sleep 10
            Send "{Shift up}"
        } else {
            Click
        }
        DebugLog("点击鼠标左键")
    }
}

/**
 * 鼠标右键点击
 */
PressRightClick() {
    global isRunning, isPaused, mouseControls, shiftEnabled
    global SKILL_MODE_CLICK, SKILL_MODE_BUFF, SKILL_MODE_HOLD

    if (!isRunning || isPaused || !mouseControls.right.enable.Value)
        return

    ; 获取当前模式
    mouseMode := mouseControls.right.mode.Value

    ; 按住模式处理
    if (mouseMode == SKILL_MODE_HOLD) {
        static rightMouseHeld := false

        if (!rightMouseHeld) {
            if (shiftEnabled)
                Send "{Shift down}"

            Click "down right"
            rightMouseHeld := true
            DebugLog("按住鼠标右键")
        }
    }
    ; 连点模式处理
    else {
        if (shiftEnabled) {
            Send "{Shift down}"
            Sleep 10
            Click "right"
            Sleep 10
            Send "{Shift up}"
        } else {
            Click "right"
        }
        DebugLog("点击鼠标右键")
    }
}

/**
 * 重置鼠标按键状态
 */
ResetMouseButtonStates() {
    static leftMouseHeld := false
    static rightMouseHeld := false

    if (leftMouseHeld) {
        Click "up left"
        leftMouseHeld := false
        DebugLog("释放鼠标左键")
    }

    if (rightMouseHeld) {
        Click "up right"
        rightMouseHeld := false
        DebugLog("释放鼠标右键")
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
    global skillControls
    section := "Skills"

    for i in [1, 2, 3, 4, 5] {
        IniWrite(skillControls[i].key.Value, file, section, "Skill" i "Key")
        IniWrite(skillControls[i].enable.Value, file, section, "Skill" i "Enable")
        IniWrite(skillControls[i].interval.Value, file, section, "Skill" i "Interval")

        ; 获取下拉框选择的索引并保存
        modeIndex := skillControls[i].mode.Value
        IniWrite(modeIndex, file, section, "Skill" i "Mode")
        DebugLog("保存技能" i "模式: " modeIndex)
    }
}

/**
 * 保存鼠标设置
 * @param {String} file - 设置文件路径
 */
SaveMouseSettings(file) {
    global mouseControls, mouseAutoMove
    section := "Mouse"

    ; 保存左键设置
    IniWrite(mouseControls.left.enable.Value, file, section, "LeftClickEnable")
    IniWrite(mouseControls.left.interval.Value, file, section, "LeftClickInterval")
    leftModeIndex := mouseControls.left.mode.Value
    IniWrite(leftModeIndex, file, section, "LeftClickMode")
    DebugLog("保存左键模式: " leftModeIndex)

    ; 保存右键设置
    IniWrite(mouseControls.right.enable.Value, file, section, "RightClickEnable")
    IniWrite(mouseControls.right.interval.Value, file, section, "RightClickInterval")
    rightModeIndex := mouseControls.right.mode.Value
    IniWrite(rightModeIndex, file, section, "RightClickMode")
    DebugLog("保存右键模式: " rightModeIndex)

    ; 保存自动移动设置
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
    IniWrite(utilityControls.huoDun.key.Value, file, section, "HuoDunKey")
    IniWrite(utilityControls.dianMao.key.Value, file, section, "DianMaoKey")
    IniWrite(utilityControls.dianQiu.key.Value, file, section, "DianQiuKey")
    IniWrite(utilityControls.binDun.key.Value, file, section, "BinDunKey")
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
    global skillControls, SKILL_MODE_CLICK

    Loop 5 {
        try {
            key := IniRead(file, "Skills", "Skill" A_Index "Key", A_Index)
            enabled := IniRead(file, "Skills", "Skill" A_Index "Enable", 1)
            interval := IniRead(file, "Skills", "Skill" A_Index "Interval", 20)
            mode := Integer(IniRead(file, "Skills", "Skill" A_Index "Mode", SKILL_MODE_CLICK))

            skillControls[A_Index].key.Value := key
            skillControls[A_Index].enable.Value := enabled
            skillControls[A_Index].interval.Value := interval

            ; 设置模式下拉框
            try {
                DebugLog("尝试设置技能" A_Index "模式为: " mode)
                if (mode >= 1 && mode <= 3) {
                    ; 直接设置Text属性而不是使用Choose方法
                    if (mode == 1)
                        skillControls[A_Index].mode.Text := "连点"
                    else if (mode == 2)
                        skillControls[A_Index].mode.Text := "BUFF"
                    else if (mode == 3)
                        skillControls[A_Index].mode.Text := "按住"

                    DebugLog("成功设置技能" A_Index "模式为: " mode)
                } else {
                    skillControls[A_Index].mode.Text := "连点"
                    DebugLog("技能" A_Index "模式值无效: " mode "，使用默认连点模式")
                }
            } catch as err {
                skillControls[A_Index].mode.Text := "连点"
                DebugLog("设置技能" A_Index "模式出错: " err.Message "，使用默认连点模式")
            }
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
    global mouseControls, mouseAutoMove, mouseAutoMoveEnabled, SKILL_MODE_CLICK

    try {
        ; 加载左键设置
        mouseControls.left.enable.Value := IniRead(file, "Mouse", "LeftClickEnable", 1)
        mouseControls.left.interval.Value := IniRead(file, "Mouse", "LeftClickInterval", 80)
        leftMode := Integer(IniRead(file, "Mouse", "LeftClickMode", SKILL_MODE_CLICK))

        ; 加载右键设置
        mouseControls.right.enable.Value := IniRead(file, "Mouse", "RightClickEnable", 0)
        mouseControls.right.interval.Value := IniRead(file, "Mouse", "RightClickInterval", 300)
        rightMode := Integer(IniRead(file, "Mouse", "RightClickMode", SKILL_MODE_CLICK))

        ; 加载自动移动设置
        mouseAutoMove.enable.Value := IniRead(file, "Mouse", "MouseAutoMoveEnable", 0)
        mouseAutoMove.interval.Value := IniRead(file, "Mouse", "MouseAutoMoveInterval", 1000)
        mouseAutoMoveEnabled := (mouseAutoMove.enable.Value = 1)

        ; 设置左键模式下拉框
        try {
            DebugLog("尝试设置左键模式为: " leftMode)
            if (leftMode >= 1 && leftMode <= 3) {
                ; 直接设置Text属性而不是使用Choose方法
                if (leftMode == 1)
                    mouseControls.left.mode.Text := "连点"
                else if (leftMode == 2)
                    mouseControls.left.mode.Text := "BUFF"
                else if (leftMode == 3)
                    mouseControls.left.mode.Text := "按住"

                DebugLog("成功设置左键模式为: " leftMode)
            } else {
                mouseControls.left.mode.Text := "连点"
                DebugLog("左键模式值无效: " leftMode "，使用默认连点模式")
            }
        } catch as err {
            mouseControls.left.mode.Text := "连点"
            DebugLog("设置左键模式出错: " err.Message "，使用默认连点模式")
        }

        ; 设置右键模式下拉框
        try {
            DebugLog("尝试设置右键模式为: " rightMode)
            if (rightMode >= 1 && rightMode <= 3) {
                ; 直接设置Text属性而不是使用Choose方法
                if (rightMode == 1)
                    mouseControls.right.mode.Text := "连点"
                else if (rightMode == 2)
                    mouseControls.right.mode.Text := "BUFF"
                else if (rightMode == 3)
                    mouseControls.right.mode.Text := "按住"

                DebugLog("成功设置右键模式为: " rightMode)
            } else {
                mouseControls.right.mode.Text := "连点"
                DebugLog("右键模式值无效: " rightMode "，使用默认连点模式")
            }
        } catch as err {
            mouseControls.right.mode.Text := "连点"
            DebugLog("设置右键模式出错: " err.Message "，使用默认连点模式")
        }

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
        utilityControls.dodge.interval.Value := IniRead(file, "Utility", "DodgeInterval", 20)

        utilityControls.potion.key.Value := IniRead(file, "Utility", "PotionKey", "q")
        utilityControls.potion.enable.Value := IniRead(file, "Utility", "PotionEnable", 0)
        utilityControls.potion.interval.Value := IniRead(file, "Utility", "PotionInterval", 3000)

        utilityControls.forceMove.key.Value := IniRead(file, "Utility", "ForceMoveKey", "``")
        utilityControls.forceMove.enable.Value := IniRead(file, "Utility", "ForceMoveEnable", 0)
        utilityControls.forceMove.interval.Value := IniRead(file, "Utility", "ForceMoveInterval", 50)
        utilityControls.huoDun.key.Value := IniRead(file, "Utility", "HuoDunKey", "2")
        utilityControls.dianMao.key.Value := IniRead(file, "Utility", "DianMaoKey", "1")
        utilityControls.dianQiu.key.Value := IniRead(file, "Utility", "DianQiuKey", "e")
        utilityControls.binDun.key.Value := IniRead(file, "Utility", "BinDunKey", "3")
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
        ; 初始化窗口分辨率和技能位置
        GetDiabloIVResolution()
        GetDynamicSkillPositions()
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
    Loop 5 {
        key := skillControls[A_Index].key.Value
        if key != "" {
            Send "{" key " up}"
            DebugLog("释放技能" A_Index " 键: " key)
        }
    }

    ; 释放鼠标按键
    SetMouseDelay -1
    Click "up left"
    Click "up right"

    ; 重置所有按住模式的按键状态
    ResetAllHoldKeyStates()

    ; 重置鼠标按键状态
    ResetMouseButtonStates()

    DebugLog("已释放所有按键")
}

/**
 * 重置所有按住模式的按键状态
 */
ResetAllHoldKeyStates() {
    ; 使用全局静态变量来跟踪按键状态
    static keyStates := Map()

    ; 清空按键状态映射
    keyStates := Map()
    DebugLog("重置所有按住模式的按键状态")
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
*F1::ToggleMacro()
; 添加热键支持
F3::{
    ; 确保从配置对象获取最新值
    dianQiuKey := utilityControls.dianQiu.key.Value
    huoDunKey := utilityControls.huoDun.key.Value
    dianMaoKey := utilityControls.dianMao.key.Value
    binDunKey := utilityControls.binDun.key.Value

    ; 添加错误处理
    try {
        ; 执行连招
        Send "{Blind}{" binDunKey "}"  ; 使用Blind模式保持Shift状态
        Sleep 75
        Loop 3 {
            Send "{Blind}{" dianQiuKey "}"
            Sleep 550
        }
        Send "{Blind}{" huoDunKey "}"
        Sleep 2700  ; 长延迟需要额外处理
        Send "{Blind}{" dianMaoKey "}"
        Sleep 550
        ToggleMacro()
    } catch as err {
        DebugLog("F3连招出错: " err.Message)
        TrayTip "连招错误", "请检查技能键配置", 3
    }
}

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

Enter::{
    global isRunning, isPaused

    ; 发送原始Tab键
    Send "{Enter}"

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

NumpadEnter::{
    global isRunning, isPaused

    ; 发送原始NumpadEnter键
    Send "{NumpadEnter}"

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
        color := PixelGetColor(x, y, "RGB")

        ; 提取绿分量
        r := (color >> 16) & 0xFF
        g := (color >> 8) & 0xFF
        b := color & 0xFF
        ; 判断绿色分量高于蓝色分量
        return (g > b + 100)
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
        screenWidth := D4W
        screenHeight := D4H

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
