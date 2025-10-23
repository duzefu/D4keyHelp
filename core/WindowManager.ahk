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