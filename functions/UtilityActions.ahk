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
 * 根据当前屏幕尺寸计算截图中的相对坐标
 * @param {Float} xRatio - X坐标占屏幕宽度的比例
 * @param {Float} yRatio - Y坐标占屏幕高度的比例
 * @returns {Object} 屏幕坐标
 */
ScalePoint(xRatio, yRatio) {
    return {x: Round(A_ScreenWidth * xRatio), y: Round(A_ScreenHeight * yRatio)}
}

/**
 * 判断背包格子中是否有物品
 * @param {Integer} centerX - 格子中心X坐标
 * @param {Integer} centerY - 格子中心Y坐标
 * @param {Integer} slotSize - 格子大小
 * @returns {Boolean} 有明显非空像素时返回true
 */
IsInventorySlotOccupied(centerX, centerY, slotSize) {
    brightPixels := 0
    sampleRadius := Max(4, Round(slotSize * 0.28))
    offsets := [
        {x: 0, y: 0},
        {x: -sampleRadius, y: -sampleRadius},
        {x: sampleRadius, y: -sampleRadius},
        {x: -sampleRadius, y: sampleRadius},
        {x: sampleRadius, y: sampleRadius},
        {x: 0, y: -sampleRadius},
        {x: 0, y: sampleRadius},
        {x: -sampleRadius, y: 0},
        {x: sampleRadius, y: 0},
        {x: -Round(sampleRadius / 2), y: -Round(sampleRadius / 2)},
        {x: Round(sampleRadius / 2), y: Round(sampleRadius / 2)}
    ]

    for _, offset in offsets {
        try {
            color := PixelGetColor(centerX + offset.x, centerY + offset.y, "RGB")
            r := (color >> 16) & 0xFF
            g := (color >> 8) & 0xFF
            b := color & 0xFF
            brightness := Max(r, g, b)
            contrast := Max(r, g, b) - Min(r, g, b)

            ; 空格子整体偏黑，装备图标通常会出现较亮或有明显色差的像素。
            if (brightness > 72 || (brightness > 48 && contrast > 24))
                brightPixels += 1
        } catch as err {
            DebugLog("自动嬗变：读取格子像素失败: " err.Message)
        }
    }

    return brightPixels >= 2
}

/**
 * 查找右下装备栏/背包 11列x3行中的所有物品
 * 坐标来自用户截图中的16:9界面布局，按当前屏幕比例缩放。
 * @returns {Array} 物品坐标数组
 */
FindInventoryItems() {
    global isAutoTransmuting

    itemPositions := []
    slotSize := Round(A_ScreenWidth * 0.030)
    startX := A_ScreenWidth * 0.676
    startY := A_ScreenHeight * 0.704
    stepX := A_ScreenWidth * 0.0305
    stepY := A_ScreenHeight * 0.061

    Loop 3 {
        row := A_Index
        Loop 11 {
            if !isAutoTransmuting
                return itemPositions

            col := A_Index
            x := Round(startX + (col - 1) * stepX)
            y := Round(startY + (row - 1) * stepY)

            if IsInventorySlotOccupied(x, y, slotSize) {
                itemPositions.Push({x: x, y: y, row: row, col: col})
                DebugLog("自动嬗变：找到物品，行=" row " 列=" col " x=" x " y=" y)
            }
        }
    }

    return itemPositions
}

/**
 * 可中断的Sleep，用于自动嬗变流程
 * @param {Integer} duration - 等待的毫秒数
 * @returns {Boolean} 正常完成返回true，被取消返回false
 */
TransmuteInterruptibleSleep(duration) {
    global isAutoTransmuting

    checkInterval := 50
    elapsed := 0

    while (elapsed < duration) {
        if !isAutoTransmuting
            return false

        sleepTime := Min(checkInterval, duration - elapsed)
        Sleep sleepTime
        elapsed += sleepTime
    }

    return true
}

/**
 * 对单个物品格执行嬗变/重塑（含绑定确认「接受」与「清除」）
 * @param {Object} itemPos - 物品格坐标
 * @returns {Boolean} 正常完成返回true，被取消返回false
 */
TransmuteInventoryItem(itemPos) {
    global isAutoTransmuting

    if !isAutoTransmuting
        return false

    MouseMove itemPos.x, itemPos.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "right"
    DebugLog("自动嬗变：右键物品 行=" itemPos.row " 列=" itemPos.col " x=" itemPos.x " y=" itemPos.y)
    if !TransmuteInterruptibleSleep(250)
        return false

    transmuteButton := ScalePoint(0.445, 0.380)
    MouseMove transmuteButton.x, transmuteButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击嬗变/配方按钮 x=" transmuteButton.x " y=" transmuteButton.y)
    if !TransmuteInterruptibleSleep(180)
        return false

    reforgeButton := ScalePoint(0.168, 0.793)
    MouseMove reforgeButton.x, reforgeButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击重塑按钮 x=" reforgeButton.x " y=" reforgeButton.y)
    if !TransmuteInterruptibleSleep(450)
        return false

    acceptButton := ScalePoint(0.432, 0.560)
    MouseMove acceptButton.x, acceptButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击接受按钮 x=" acceptButton.x " y=" acceptButton.y)
    if !TransmuteInterruptibleSleep(1000)
        return false

    clearButton := ScalePoint(0.168, 0.680)
    MouseMove clearButton.x, clearButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击清除按钮 x=" clearButton.x " y=" clearButton.y)
    return TransmuteInterruptibleSleep(350)
}

/**
 * 自动嬗变：扫描右下装备栏/背包33格，逐个右键物品、点击嬗变/配方、点击重塑、确认接受、等待1秒后清除
 */
AutoTransmute(*) {
    global isRunning, isPaused, isAutoTransmuting

    if !WinActive("ahk_class Diablo IV Main Window Class")
        return

    if isAutoTransmuting {
        isAutoTransmuting := false
        DebugLog("自动嬗变：用户请求取消")
        return
    }

    shouldResume := isRunning && !isPaused
    isAutoTransmuting := true
    processedCount := 0
    totalCount := 0
    cancelled := false

    try {
        CoordMode "Mouse", "Screen"
        CoordMode "Pixel", "Screen"

        if shouldResume {
            StopAllTimers()
            DebugLog("自动嬗变：已暂停宏定时器")
        }

        itemPositions := FindInventoryItems()
        if !isAutoTransmuting {
            cancelled := true
        } else {
            totalCount := itemPositions.Length
            if (totalCount = 0) {
                UpdateStatus("未找到装备物品", "自动嬗变：装备栏/背包没有识别到物品")
                DebugLog("自动嬗变：未找到物品")
                return
            }

            DebugLog("自动嬗变：共识别到 " totalCount " 个物品")
            for index, itemPos in itemPositions {
                if !isAutoTransmuting {
                    cancelled := true
                    break
                }

                UpdateStatus("自动嬗变中", "正在处理第 " index "/" totalCount " 个物品（F3 取消）")
                if TransmuteInventoryItem(itemPos)
                    processedCount += 1
                else {
                    cancelled := true
                    break
                }
            }
        }

        if cancelled {
            UpdateStatus("已取消", "自动嬗变已取消，已处理 " processedCount "/" totalCount " 个物品")
            DebugLog("自动嬗变：已取消，已处理 " processedCount "/" totalCount " 个物品")
        } else {
            UpdateStatus("自动嬗变完成", "已处理 " processedCount " 个物品")
        }
    } catch as err {
        UpdateStatus("自动嬗变失败", "自动嬗变失败: " err.Message)
        DebugLog("自动嬗变失败: " err.Message)
    } finally {
        isAutoTransmuting := false
        if shouldResume && isRunning {
            StartAllTimers()
            DebugLog("自动嬗变：已恢复宏定时器")
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