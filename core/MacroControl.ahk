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

/**
 * 切换鼠标点击暂停宏功能
 */
TogglePauseOnClick(*) {
    global pauseOnClickEnabled, pauseOnClick

    pauseOnClickEnabled := !pauseOnClickEnabled
    
    ; 更新GUI勾选框状态以匹配当前状态
    pauseOnClick.enable.Value := pauseOnClickEnabled ? 1 : 0

    DebugLog("鼠标点击暂停宏状态切换: " . (pauseOnClickEnabled ? "启用" : "禁用"))
}

/**
 * 鼠标点击后恢复宏运行
 */
ResumeAfterClickPause() {
    global isRunning, isPaused, temporaryPaused
    
    ; 停止恢复定时器
    SetTimer(ResumeAfterClickPause, 0)
    
    ; 如果宏仍在运行中且是临时暂停状态，则恢复宏
    if (isRunning && temporaryPaused) {
        ; 恢复宏运行
        StartAllTimers()
        temporaryPaused := false
        UpdateStatus("运行中", "宏已从鼠标点击暂停中恢复")
        DebugLog("宏已从鼠标点击暂停中恢复")
    }
}