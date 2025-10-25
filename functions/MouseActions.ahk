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