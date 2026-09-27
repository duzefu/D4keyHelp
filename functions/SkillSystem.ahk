; ========== 技能系统 ==========
; ---------- 维持BUFF取色点标定（动作栏槽位） ----------
; "维持BUFF" 的判据：动作栏（技能栏）每个格子的顶部有一条绿色指示条，
; 技能效果生效时，该格左上角会出现这条绿条（贴住格子左缘，向右延伸 7~28px）。
; 检测点就取绿条起点，位置按屏幕高度等比缩放（与血球识别同一套做法）。
;
; 标定数据（真实截图实测）：
;   2K(2560x1440)：1 号格绿条起点 x=1035、相邻格间距 84、绿条所在 y=1290
;   1080P(1920x1080)：绿条起点 x=776 / 839 / 902 / 965 / 1028 / 1091
;                     绿条 y=967..970；绿条像素 RGB≈(115,174,14)，未生效处 RGB≈(16,31,33)
; 标定截图：1790432325125.png(1080P)、0c3625c4-745f-49c4-b506-5c189ef1f439.png(2K)
; 注意：与血球识别一样读的是屏幕像素，需要游戏在前台全屏/无边框全屏；
;       游戏内 UI 需设置为技能框在正中下方，改动标定后请重跑 tests/SkillBuffTest.ahk
global SKILL_SLOT_BASE_X := 1035   ; 2K 下 1 号格绿条起点 x
global SKILL_SLOT_BASE_Y := 1290   ; 2K 下绿条所在 y
global SKILL_SLOT_STEP := 84       ; 2K 下相邻格间距
global SKILL_SLOT_REF_W := 2560    ; 标定所用参考分辨率
global SKILL_SLOT_REF_H := 1440
global SKILL_SLOT_ORDER := [1, 2, 3, 4, "left", "right"]   ; 动作栏从左到右

/**
 * 技能槽（动作栏格子）左上角坐标，也就是"BUFF生效绿条"的起点
 * 2K 标定值按屏幕高度等比缩放，横向以屏幕中线为基准（动作栏居中）
 * @param {Integer|String} slot - 技能槽（1-4 / "left" / "right"）
 * @param {Integer} screenW, screenH - 屏幕尺寸，默认取当前屏幕（便于测试）
 * @returns {Object|""} {x, y, scale}；未知槽位返回 ""
 */
GetSkillSlotPos(slot, screenW := 0, screenH := 0) {
    global SKILL_SLOT_BASE_X, SKILL_SLOT_BASE_Y, SKILL_SLOT_STEP
    global SKILL_SLOT_REF_W, SKILL_SLOT_REF_H, SKILL_SLOT_ORDER

    slotIndex := 0
    for i, name in SKILL_SLOT_ORDER {
        if (String(name) = String(slot)) {
            slotIndex := i
            break
        }
    }
    if (!slotIndex)
        return ""

    if (!screenW)
        screenW := A_ScreenWidth
    if (!screenH)
        screenH := A_ScreenHeight

    scale := screenH / SKILL_SLOT_REF_H
    baseX := SKILL_SLOT_BASE_X + SKILL_SLOT_STEP * (slotIndex - 1)
    return {x: Round(screenW / 2 + (baseX - SKILL_SLOT_REF_W / 2) * scale)
        , y: Round(SKILL_SLOT_BASE_Y * scale), scale: scale}
}

/**
 * "绿条"采样点偏移（相对槽位左上角）
 * 绿条贴着格子左上角，2K 下实测横向 0~8px、纵向 -1~+2px，
 * 取一组小范围采样点，既能容忍缩放取整误差，也能取到 BUFF 快掉时只剩一小段的绿条
 * @param {Float} scale - 屏幕高度缩放系数
 * @returns {Array} [{dx, dy}, ...]
 */
GetBuffSampleOffsets(scale) {
    offsets := []
    for dy in [-1, 0, 1, 2]
        for dx in [0, 2, 5, 8]
            offsets.Push({dx: Round(dx * scale), dy: Round(dy * scale)})
    return offsets
}

/**
 * 绿条像素判据：绿色分量明显高于红蓝
 * 实测绿条 RGB≈(115,174,14)；未生效处是灰蓝边框 RGB≈(16,31,33)、灰底 RGB≈(100,99,97)，
 * 只判"绿色分量>60"会把灰底也算成生效，所以要求绿色分量明显占优
 * @param {Integer} color - PixelGetColor 返回值（0xRRGGBB）
 * @returns {Boolean}
 */
IsBuffIndicatorColor(color) {
    r := (color >> 16) & 0xFF
    g := (color >> 8) & 0xFF
    b := color & 0xFF
    return (g > 60 && (g - r) >= 20 && (g - b) >= 20)
}

/**
 * 按下技能键
 * @param {Integer} skillNum - 技能编号(1-4)
 */
PressSkill(skillNum) {
    global isRunning, isPaused, skillControls
    global SKILL_MODE_CLICK, SKILL_MODE_BUFF, SKILL_MODE_HOLD
    global holdKeyStates, boundCheckHoldTimers

    ; 检查基本条件：策略不为禁用(1)
    if (!isRunning || isPaused || skillControls[skillNum].strategy.Value <= 1)
        return

    ; 获取按键
    key := skillControls[skillNum].key.Value
    if (key = "")
        return

    ; 从策略值转换为模式值（策略-1=模式）
    skillMode := skillControls[skillNum].strategy.Value - 1

    ; 根据不同模式处理
    if (skillMode = SKILL_MODE_BUFF) {
        ; 维持BUFF模式 - 检查技能是否已激活
        if ShouldSkipBuffPress(skillNum)
            return

        ; 发送按键
        SendKey(key)
        DebugLog("按下技能" skillNum " 键(维持BUFF模式): " key, 2)
    }
    else if (skillMode = SKILL_MODE_HOLD) {
        ; 按住模式 - 按下并保持按键
        ; 如果按键未按下，则按下并记录状态
        if (!holdKeyStates.Has(skillNum) || !holdKeyStates[skillNum]) {
            Send "{" key " down}"
            holdKeyStates[skillNum] := true
            DebugLog("按住技能" skillNum " 键: " key, 2)

            ; 设置一个定时器，每5秒检查一次是否需要继续按住
            ; 保存绑定引用，便于后续SetTimer(..., 0)停止
            boundCheckHoldTimers[skillNum] := CheckHoldKey.Bind(skillNum, key)
            SetTimer(boundCheckHoldTimers[skillNum], 5000)
        }
    }
    else {
        ; 默认连点模式 - 直接发送按键
        SendKey(key)
        DebugLog("按下技能" skillNum " 键(连点模式): " key, 2)
    }
}

/**
 * 维持BUFF模式：判断本次是否应跳过按键
 * 绿条存在（BUFF生效中）时跳过；按键频率由该槽位设置的间隔控制
 * @param {Integer|String} slot - 技能槽（1-4 / "left" / "right"）
 * @returns {Boolean} - true表示跳过
 */
ShouldSkipBuffPress(slot) {
    try {
        pos := GetSkillSlotPos(slot)
        if (IsObject(pos) && IsSkillActive(pos.x, pos.y)) {
            DebugLog("技能" slot "已激活，跳过", 2)
            return true
        }
    } catch as err {
        DebugLog("检测技能状态出错: " err.Message)
    }

    return false
}

/**
 * 检查按住的按键是否需要释放
 * @param {Integer} skillNum - 技能编号
 * @param {String} key - 按键
 */
CheckHoldKey(skillNum, key) {
    global isRunning, isPaused, skillControls, SKILL_MODE_HOLD
    global holdKeyStates, boundCheckHoldTimers

    ; 如果宏停止、暂停或策略改变，释放按键
    if (!isRunning || isPaused ||
        skillControls[skillNum].strategy.Value <= 1 ||
        (skillControls[skillNum].strategy.Value - 1) != SKILL_MODE_HOLD) {

        if (holdKeyStates.Has(skillNum) && holdKeyStates[skillNum]) {
            Send "{" key " up}"
            holdKeyStates[skillNum] := false
            DebugLog("释放技能" skillNum " 键: " key, 2)

            ; 用保存的绑定引用停止定时器
            if (boundCheckHoldTimers.Has(skillNum)) {
                SetTimer(boundCheckHoldTimers[skillNum], 0)
                boundCheckHoldTimers.Delete(skillNum)
            }
        }
    }
}

/**
 * 检测技能槽位是否处于生效状态（槽位左上角是否有绿条）
 * @param {Integer} x, y - 槽位左上角坐标（GetSkillSlotPos 返回）
 * @returns {Boolean} - true 表示 BUFF 生效中
 */
IsSkillActive(x, y) {
    scale := A_ScreenHeight / 1440
    prevMode := CoordMode("Pixel", "Screen")   ; 槽位按屏幕坐标标定（血球识别同为屏幕坐标）
    try {
        for offset in GetBuffSampleOffsets(scale) {
            color := PixelGetColor(Round(x + offset.dx), Round(y + offset.dy))
            if (IsBuffIndicatorColor(color))
                return true
        }
    } catch as err {
        DebugLog("检测技能状态失败: " err.Message)
        return false
    } finally {
        CoordMode("Pixel", prevMode)
    }

    return false
}