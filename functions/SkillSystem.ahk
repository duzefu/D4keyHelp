; ========== 技能系统 ==========
/**
 * 按下技能键
 * @param {Integer} skillNum - 技能编号(1-4)
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
        ; 按住模式 - 按下并保持按键
        static keyStates := Map()

        ; 如果按键未按下，则按下并记录状态
        if (!keyStates.Has(skillNum) || !keyStates[skillNum]) {
            Send "{" key " down}"
            keyStates[skillNum] := true
            DebugLog("按住技能" skillNum " 键: " key)

            ; 设置一个定时器，每5秒检查一次是否需要继续按住
            checkTimer := CheckHoldKey.Bind(skillNum, key)
            SetTimer(checkTimer, 5000)
        }
    }
    else {
        ; 默认连点模式 - 直接发送按键
        SendKey(key)
        DebugLog("按下技能" skillNum " 键(连点模式): " key)
    }
}

/**
 * 检查按住的按键是否需要释放
 * @param {Integer} skillNum - 技能编号
 * @param {String} key - 按键
 */
CheckHoldKey(skillNum, key) {
    global isRunning, isPaused, skillControls, SKILL_MODE_HOLD
    static keyStates := Map()

    ; 如果宏停止、暂停或模式改变，释放按键
    if (!isRunning || isPaused ||
        !skillControls[skillNum].enable.Value ||
        skillControls[skillNum].mode.Value != SKILL_MODE_HOLD) {

        if (keyStates.Has(skillNum) && keyStates[skillNum]) {
            Send "{" key " up}"
            keyStates[skillNum] := false
            DebugLog("释放技能" skillNum " 键: " key)

            ; 停止定时器
            SetTimer(CheckHoldKey.Bind(skillNum, key), 0)
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