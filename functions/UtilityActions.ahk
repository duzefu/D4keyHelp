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
 * 按像素 RGB 快速分类：red / yellow / blue / dark / other（无 HSV，供批量扫描）
 */
ClassifyInventoryPixelFast(r, g, b) {
    brightness := Max(r, g, b)
    contrast := brightness - Min(r, g, b)

    if (brightness <= 48 || (brightness <= 72 && contrast <= 24))
        return "dark"

    if (g >= 45 && r >= 45 && b <= 35 && Abs(r - g) <= 40 && r >= b + 8) {
        if !(r >= g + 18 && r >= b + 30)
            return "yellow"
    }

    if (b >= r && b >= g && (b - r) >= 6)
        return "blue"

    if (r >= 55 && r >= g + 12 && r >= b + 25)
        return "red"

    if (r >= 38 && g >= 28 && (r - g) < 18 && r > b && g > b)
        return "yellow"

    return "other"
}

/**
 * 获取单格采样偏移（中心 + 边框，共 11 点）
 */
GetInventorySampleOffsets(slotSize) {
    sampleRadius := Max(4, Round(slotSize * 0.28))
    return [
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
}

/**
 * 从内存位图读取像素 RGB
 */
ReadCapturedPixel(capture, screenX, screenY) {
    localX := screenX - capture.originX
    localY := screenY - capture.originY
    if (localX < 0 || localY < 0 || localX >= capture.width || localY >= capture.height)
        return {r: 0, g: 0, b: 0}

    offset := localY * capture.stride + localX * 3
    return {
        b: NumGet(capture.bits, offset, "UChar"),
        g: NumGet(capture.bits, offset + 1, "UChar"),
        r: NumGet(capture.bits, offset + 2, "UChar")
    }
}

/**
 * 一次性截取装备栏区域（11x3 格），避免逐点 PixelGetColor
 */
CaptureInventoryGridBitmap(startX, startY, stepX, stepY, slotSize) {
    sampleRadius := Max(4, Round(slotSize * 0.28))
    originX := Round(startX) - sampleRadius
    originY := Round(startY) - sampleRadius
    endX := Round(startX + 10 * stepX) + sampleRadius
    endY := Round(startY + 2 * stepY) + sampleRadius
    width := endX - originX + 1
    height := endY - originY + 1

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcMem := DllCall("CreateCompatibleDC", "Ptr", 0, "Ptr")
    hBitmap := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", width, "Int", height, "Ptr")
    oldBitmap := DllCall("SelectObject", "Ptr", hdcMem, "Ptr", hBitmap, "Ptr")
    DllCall("gdi32\BitBlt", "Ptr", hdcMem, "Int", 0, "Int", 0, "Int", width, "Int", height
        , "Ptr", hdcScreen, "Int", originX, "Int", originY, "UInt", 0x00CC0020)

    bi := Buffer(40, 0)
    NumPut("UInt", 40, bi, 0)
    NumPut("Int", width, bi, 4)
    NumPut("Int", -height, bi, 8)
    NumPut("UShort", 1, bi, 12)
    NumPut("UShort", 24, bi, 14)

    stride := ((width * 3 + 3) // 4) * 4
    bits := Buffer(stride * height)
    ok := DllCall("gdi32\GetDIBits", "Ptr", hdcMem, "Ptr", hBitmap, "UInt", 0, "Int", height
        , "Ptr", bits, "Ptr", bi, "UInt", 0)

    DllCall("SelectObject", "Ptr", hdcMem, "Ptr", oldBitmap)
    DllCall("DeleteObject", "Ptr", hBitmap)
    DllCall("DeleteDC", "Ptr", hdcMem)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)

    return {bits: bits, stride: stride, width: width, height: height, originX: originX, originY: originY, ok: ok}
}

/**
 * 从已截取的位图判断格子主色调
 */
ClassifyInventorySlotFromCapture(capture, centerX, centerY, offsets) {
    votes := Map("red", 0, "yellow", 0, "blue", 0, "other", 0, "dark", 0)
    totalSamples := 0
    sumR := 0
    sumG := 0
    sumB := 0
    brightCount := 0

    for _, offset in offsets {
        rgb := ReadCapturedPixel(capture, centerX + offset.x, centerY + offset.y)
        pixelKind := ClassifyInventoryPixelFast(rgb.r, rgb.g, rgb.b)
        votes[pixelKind] += 1
        totalSamples += 1
        if (pixelKind != "dark") {
            sumR += rgb.r
            sumG += rgb.g
            sumB += rgb.b
            brightCount += 1
        }
    }

    if (totalSamples = 0)
        return "other"

    if (votes["dark"] / totalSamples >= 0.72)
        return "other"

    if (votes["blue"] >= 3 && votes["blue"] > votes["red"] && votes["blue"] > votes["yellow"])
        return "other"

    if (votes["red"] >= 3 && votes["red"] > votes["yellow"] && votes["red"] > votes["blue"])
        return "red"

    redYellowVotes := votes["red"] + votes["yellow"]
    if (redYellowVotes >= 2) {
        redRatio := votes["red"] / redYellowVotes
        if (redRatio >= 0.58)
            return "red"
        if (redRatio <= 0.35)
            return "yellow"
    }

    if (brightCount >= 3) {
        avgR := sumR / brightCount
        avgG := sumG / brightCount
        avgB := sumB / brightCount
        if (avgR >= 52 && (avgR - avgG) >= 14 && (avgR - avgB) >= 32 && votes["red"] >= 1
            && votes["red"] >= votes["yellow"])
            return "red"
    }

    return "other"
}

/**
 * 查找右下装备栏/背包 11列x3行中的传奇物品（单次截图 + 内存取色，目标 <2s）
 */
FindInventoryItems() {
    global isAutoTransmuting

    itemPositions := []
    slotSize := Round(A_ScreenWidth * 0.030)
    startX := A_ScreenWidth * 0.676
    startY := A_ScreenHeight * 0.704
    stepX := A_ScreenWidth * 0.0305
    stepY := A_ScreenHeight * 0.061
    scanStart := A_TickCount

    capture := CaptureInventoryGridBitmap(startX, startY, stepX, stepY, slotSize)
    if !capture.ok {
        DebugLog("自动嬗变：装备栏区域截图失败")
        return itemPositions
    }

    offsets := GetInventorySampleOffsets(slotSize)

    Loop 3 {
        row := A_Index
        Loop 11 {
            if !isAutoTransmuting
                return itemPositions

            col := A_Index
            x := Round(startX + (col - 1) * stepX)
            y := Round(startY + (row - 1) * stepY)

            if (ClassifyInventorySlotFromCapture(capture, x, y, offsets) = "red")
                itemPositions.Push({x: x, y: y, row: row, col: col})
        }
    }

    DebugLog("自动嬗变：扫描完成，耗时 " (A_TickCount - scanStart) "ms，找到 "
        itemPositions.Length " 个传奇物品")
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
                UpdateStatus("未找到传奇物品", "自动嬗变：装备栏/背包没有识别到暗金/传奇装备")
                DebugLog("自动嬗变：未找到传奇物品")
                return
            }

            DebugLog("自动嬗变：共识别到 " totalCount " 个传奇物品")
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