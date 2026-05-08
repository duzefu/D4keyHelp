; ========== 功能键动作 ==========
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
 * 按下翻滚键(空格)
 */
PressDodge() {
    global isRunning, isPaused, utilityControls

    if (isRunning && !isPaused && utilityControls.dodge.enable.Value = 1) {
        SendKey("Space")
        DebugLog("按下翻滚键")
    }
}

/**
 * 按下喝药键
 */
PressPotion() {
    global isRunning, isPaused, utilityControls

    if (isRunning && !isPaused && utilityControls.potion.enable.Value = 1) {
        key := utilityControls.potion.key.Value
        if (key != "") {
            SendKey(key)
            DebugLog("按下喝药键: " key)
        }
    }
}

/**
 * 按下强制移动键
 */
PressForceMove() {
    global isRunning, isPaused, utilityControls

    if (isRunning && !isPaused && utilityControls.forceMove.enable.Value = 1) {
        key := utilityControls.forceMove.key.Value
        if (key != "") {
            SendKey(key)
            DebugLog("按下强制移动键: " key)
        }
    }
}

/**
 * 重置所有按住模式的按键状态
 * 释放任何仍处于按下状态的技能键、停止对应的检查定时器
 */
ResetAllHoldKeyStates() {
    global holdKeyStates, boundCheckHoldTimers, skillControls

    ; 释放所有仍在按下的Hold模式按键并停止其检查定时器
    for skillNum, isHeld in holdKeyStates {
        if (isHeld && skillControls.Has(skillNum)) {
            key := skillControls[skillNum].key.Value
            if (key != "") {
                Send "{" key " up}"
                DebugLog("ResetAllHoldKeyStates 释放技能" skillNum " 键: " key)
            }
        }
        if (boundCheckHoldTimers.Has(skillNum)) {
            SetTimer(boundCheckHoldTimers[skillNum], 0)
        }
    }

    holdKeyStates := Map()
    boundCheckHoldTimers := Map()
    DebugLog("重置所有按住模式的按键状态")
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