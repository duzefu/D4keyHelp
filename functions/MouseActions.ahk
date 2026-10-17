; ========== 鼠标动作 ==========
/**
 * 可中断的Sleep函数
 * 在Sleep期间检查宏是否被停止，如果停止则立即返回
 * @param {Integer} duration - 等待的毫秒数
 * @return {Boolean} - 如果正常完成返回true，如果被中断返回false
 */
InterruptibleSleep(duration) {
    global isRunning, compassPaused

    ; 将睡眠时间分成100ms的小块，以便能够快速响应中断
    checkInterval := 100
    elapsed := 0

    while (elapsed < duration) {
        ; 检查宏是否已停止
        if (!isRunning) {
            DebugLog("罗盘功能：检测到宏已停止，中断执行")
            ; 清理罗盘暂停状态
            compassPaused := false
            return false
        }

        ; 计算本次sleep的时间
        sleepTime := Min(checkInterval, duration - elapsed)
        Sleep sleepTime
        elapsed += sleepTime
    }

    return true
}

; ---------- 左右键技能行的按键 ----------
; 左右键技能行的按键框是可输入的下拉框（ComboBox）：
;   下拉列表里的两项代表鼠标左键 / 右键，也可以直接输入任意键名（如 5、F、XButton1），
;   用于把游戏里的左右键技能改绑到键盘后照样由这一行驱动，想绑回鼠标时从下拉里重新选即可。
; 存盘存的是 AHK 键名（LButton / RButton / 5 …），与界面语言无关。
; 输入框里可能是任意字符串，所以每个框记着"最后一次有效按键"（ctrl.lastValidKey）：
;   失去焦点时输入无效就恢复成它并提示；运行与存盘也都以它兜底，保证三者一致。
global MOUSE_SLOT_KEYS := ["LButton", "RButton"]   ; 下拉列表各项对应的键名
global MOUSE_SLOT_DEFAULTS := Map("left", "LButton", "right", "RButton")

/**
 * 左右键技能行下拉列表的显示文字（顺序与 MOUSE_SLOT_KEYS 一致）
 */
GetMouseSlotKeyNames() {
    return [L("mouseKey.lbutton"), L("mouseKey.rbutton")]
}

/**
 * 把按键框里的内容解析成 AHK 键名
 * @param {Gui.ComboBox} ctrl - 左右键技能行的按键框
 * @returns {String} 规范化后的键名；输入无法识别时返回 ""
 */
ResolveMouseSlotKey(ctrl) {
    global MOUSE_SLOT_KEYS

    ; 按文字判断而不是 ctrl.Value：程序改 Text 时下拉的选中项不会跟着清掉
    text := Trim(ctrl.Text)
    if (text = "")
        return ""

    ; 选中了下拉项（或手动输入了与下拉项相同的文字）
    for i, name in GetMouseSlotKeyNames() {
        if (text = name)
            return MOUSE_SLOT_KEYS[i]
    }

    ; GetKeyName 能识别的才是有效键名，顺便统一大小写（lbutton -> LButton）
    return GetKeyName(text)
}

/**
 * 把键名填回按键框：鼠标左右键选中对应下拉项，其他键直接显示键名
 * @param {Gui.ComboBox} ctrl - 左右键技能行的按键框
 * @param {String} key - AHK 键名
 */
SetMouseSlotKey(ctrl, key) {
    global MOUSE_SLOT_KEYS

    for i, name in MOUSE_SLOT_KEYS {
        if (key = name) {
            ctrl.Choose(i)
            ctrl.lastValidKey := key
            return
        }
    }
    ctrl.Choose(0)
    ctrl.Text := key
    ctrl.lastValidKey := key
}

/**
 * 取左右键技能行当前生效的按键：输入有效用输入值，否则用最后一次有效按键
 * @param {Gui.ComboBox} ctrl - 左右键技能行的按键框
 * @returns {String} AHK 键名
 */
GetMouseSlotKey(ctrl) {
    key := ResolveMouseSlotKey(ctrl)
    return (key != "") ? key : ctrl.lastValidKey
}

/**
 * 按键框内容变化：输入有效时记为最后一次有效按键（输入中途的无效内容不覆盖它）
 */
OnMouseSlotKeyChange(ctrl, *) {
    key := ResolveMouseSlotKey(ctrl)
    if (key != "")
        ctrl.lastValidKey := key
}

/**
 * 按键框失去焦点：输入无效则恢复为最后一次有效按键并提示，有效则规范显示（xbutton1 -> XButton1）
 */
OnMouseSlotKeyBlur(ctrl, *) {
    global statusBar

    key := ResolveMouseSlotKey(ctrl)
    if (key = "") {
        invalidText := ctrl.Text
        key := ctrl.lastValidKey
        if (statusBar != "")
            statusBar.Text := L("mouseKey.invalid", invalidText, key)
        DebugLog("左右键技能按键输入无效: " invalidText "，恢复为 " key)
    }
    SetMouseSlotKey(ctrl, key)
}

/**
 * 鼠标左键技能（定时器回调）
 */
PressLeftClick() {
    PressMouseSlot("left")
}

/**
 * 鼠标右键技能（定时器回调）
 */
PressRightClick() {
    PressMouseSlot("right")
}

/**
 * 左右键技能行的按键动作
 * 按键可以是鼠标键也可以是键盘键，统一用 Send 发送（Send "{LButton}" 与 Click 等效）
 * @param {String} slot - "left" / "right"
 */
PressMouseSlot(slot) {
    global isRunning, isPaused, mouseControls, shiftEnabled, SKILL_MODE_HOLD, SKILL_MODE_BUFF
    global mouseHoldStates

    control := mouseControls.%slot%
    if (!isRunning || isPaused || control.strategy.Value <= 1)
        return

    key := GetMouseSlotKey(control.key)

    mouseMode := control.strategy.Value - 1

    if (mouseMode = SKILL_MODE_BUFF) {
        if ShouldSkipBuffPress(slot)
            return
        SendKey(key)
        DebugLog(slot "键技能按下(维持BUFF模式): " key, 2)
    } else if (mouseMode = SKILL_MODE_HOLD) {
        if (mouseHoldStates[slot] = "") {
            if (shiftEnabled)
                Send "{Shift down}"

            Send "{" key " down}"
            ; 记下按住的是哪个键，释放时按它松开（期间改了按键也不会卡键）
            mouseHoldStates[slot] := key
            DebugLog(slot "键技能按住: " key, 2)
        }
    } else {
        SendKey(key)
        DebugLog(slot "键技能按下: " key, 2)
    }
}

/**
 * 重置鼠标按键状态
 */
ResetMouseButtonStates() {
    global mouseHoldStates

    for slot in ["left", "right"] {
        key := mouseHoldStates[slot]
        if (key != "") {
            Send "{" key " up}"
            mouseHoldStates[slot] := ""
            DebugLog(slot "键技能释放: " key, 2)
        }
    }

    Send "{Shift up}"
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

        DebugLog("鼠标自动移动到点" mouseAutoMoveCurrentPoint ": x=" currentPoint.x ", y=" currentPoint.y, 2)
    } catch as err {
        DebugLog("鼠标自动移动失败: " err.Message)
    }
}

/**
 * 罗盘专用功能 - 每隔65秒点击屏幕指定位置
 */
CompassClick() {
    global isRunning, isPaused, compassEnabled, compassPaused

    if (!isRunning || !compassEnabled)
        return

    ; 允许此函数被热键中断
    Critical "Off"

    try {
        DebugLog("罗盘功能开始执行")

        ; 1. 暂停所有宏
        compassPaused := true
        StopAllTimers()
        DebugLog("罗盘功能：已暂停所有宏")

        ; 2. 计算屏幕点击位置 (x=0.5, y=0.47)
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight
        clickX := screenWidth * 0.5
        clickY := screenHeight * 0.47

        ; 3. 先移动鼠标到目标位置
        MouseMove clickX, clickY, 0
        DebugLog("罗盘功能：鼠标移动到 x=" clickX ", y=" clickY)

        ; 4. 可中断的等待500ms让游戏识别鼠标位置
        if (!InterruptibleSleep(500))
            return

        ; 5. 点击屏幕中心偏上位置4次，间隔50ms
        Click clickX, clickY
        DebugLog("罗盘功能：第一次点击 x=" clickX ", y=" clickY)
        if (!InterruptibleSleep(50))
            return
        Click clickX, clickY
        if (!InterruptibleSleep(50))
            return
        Click clickX, clickY
        if (!InterruptibleSleep(50))
            return
        Click clickX, clickY
        DebugLog("罗盘功能：第四次点击 x=" clickX ", y=" clickY)

        ; 6. 可中断的等待2秒后恢复宏
        DebugLog("罗盘功能：等待2秒...")
        if (!InterruptibleSleep(2000))
            return

        ; 7. 恢复所有宏运行
        if (isRunning && compassPaused) {
            StartAllTimers()
            compassPaused := false
            DebugLog("罗盘功能：已恢复所有宏")
        }

        DebugLog("罗盘功能执行完成")
    } catch as err {
        DebugLog("罗盘功能执行失败: " err.Message)
    } finally {
        ; 确保清理compassPaused状态
        ; 如果宏仍在运行且处于罗盘暂停状态，则恢复
        if (isRunning && compassPaused) {
            StartAllTimers()
            compassPaused := false
            DebugLog("罗盘功能：finally块恢复宏运行")
        } else if (compassPaused) {
            ; 如果宏已停止但compassPaused还是true，清理状态
            compassPaused := false
            DebugLog("罗盘功能：finally块清理compassPaused状态")
        }
    }
}
