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
 * 按像素 RGB 快速分类装备品质（只看右下角采样点）
 * 颜色簇（2K 实测，取右下角小块平均值）：
 *   红装(传奇/暗金) R≈120-130 G≈55-74 B≈20-30  → R≫G≫B
 *   黄装(稀有)      R≈84-92  G≈63-68 B≈10      → R≈G，B 极低
 *   蓝装(魔法)      R≈31-34  G≈44-50 B≈70-77   → B>G>R
 *   空格/暗背景      各通道都低且接近
 * @returns {String} red / yellow / blue / dark / other
 */
ClassifyInventoryPixelFast(r, g, b) {
    brightness := Max(r, g, b)
    contrast := brightness - Min(r, g, b)

    ; 蓝装（魔法）：蓝通道明显高于红/绿
    if (b >= r + 15 && b >= g + 12 && b >= 55)
        return "blue"

    ; 空格 / 暗背景
    if (brightness < 48 || (brightness < 60 && contrast < 20))
        return "dark"

    ; 红装（传奇/暗金）：红通道占绝对主导
    if (r >= 100 && (r - g) >= 34 && r >= b + 40)
        return "red"

    ; 黄装（稀有）：红绿都较高且接近，蓝很低
    if (r >= 58 && g >= 45 && b <= 40 && (r - g) <= 34 && r >= b + 25)
        return "yellow"

    return "other"
}

/**
 * 装备格右下角采样偏移（品质色边框在此处最稳定）
 * 格子为长方形（约 73 宽 x 108 高），X/Y 采用不同比例
 */
GetInventoryBottomRightOffset(stepX, stepY) {
    return {x: Round(stepX * 0.36), y: Round(stepY * 0.39)}
}

/**
 * 右下角采样小块半径（取 7x7 平均，抗物品图标/网格线干扰）
 */
GetInventorySampleRadius() {
    return 3
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
 * 从内存位图读取以 (screenX, screenY) 为中心、半径 radius 的小块平均 RGB
 * 单像素易被物品图标或网格线干扰，小块平均显著提升识别稳定性
 */
ReadCapturedPatchAvg(capture, screenX, screenY, radius) {
    sumR := 0, sumG := 0, sumB := 0, count := 0

    Loop (2 * radius + 1) {
        dy := A_Index - 1 - radius
        localY := screenY + dy - capture.originY
        if (localY < 0 || localY >= capture.height)
            continue

        Loop (2 * radius + 1) {
            dx := A_Index - 1 - radius
            localX := screenX + dx - capture.originX
            if (localX < 0 || localX >= capture.width)
                continue

            offset := localY * capture.stride + localX * 3
            sumB += NumGet(capture.bits, offset, "UChar")
            sumG += NumGet(capture.bits, offset + 1, "UChar")
            sumR += NumGet(capture.bits, offset + 2, "UChar")
            count += 1
        }
    }

    if (count = 0)
        return {r: 0, g: 0, b: 0}

    return {r: sumR // count, g: sumG // count, b: sumB // count}
}

/**
 * 一次性截取装备栏区域（11x3 格），避免逐点 PixelGetColor
 */
CaptureInventoryGridBitmap(startX, startY, stepX, stepY) {
    offset := GetInventoryBottomRightOffset(stepX, stepY)
    margin := GetInventorySampleRadius() + 4
    originX := Round(startX) - margin
    originY := Round(startY) - margin
    endX := Round(startX + 10 * stepX + offset.x) + margin
    endY := Round(startY + 2 * stepY + offset.y) + margin
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
 * 从已截取的位图判断格子品质（仅取右下角小块平均）
 * @returns {String} red=传奇/暗金 yellow=稀有 blue=魔法 dark=空格 other=未知
 */
ClassifyInventorySlotFromCapture(capture, centerX, centerY, stepX, stepY) {
    offset := GetInventoryBottomRightOffset(stepX, stepY)
    rgb := ReadCapturedPatchAvg(capture, centerX + offset.x, centerY + offset.y, GetInventorySampleRadius())
    return ClassifyInventoryPixelFast(rgb.r, rgb.g, rgb.b)
}

/**
 * 查找右下装备栏/背包 11列x3行中的传奇物品（单次截图 + 内存取色，目标 <2s）
 *
 * 网格参数按 2K(2560x1440) 实测标定（取每格右下角品质色）：
 *   列：首格中心 x=1726.7，列间距 73.36（11 列）
 *   行：首行中心 y=1018，  行间距 108  （3 行，格子为长方形）
 * @param {String} targetQuality 目标品质：red(默认,传奇/暗金)、yellow、blue、redyellow(红+黄)、any
 */
FindInventoryItems(targetQuality := "red") {
    global isAutoTransmuting

    itemPositions := []
    startX := A_ScreenWidth * 0.674484
    startY := A_ScreenHeight * 0.706944
    stepX := A_ScreenWidth * 0.0286563
    stepY := A_ScreenHeight * 0.075
    scanStart := A_TickCount

    capture := CaptureInventoryGridBitmap(startX, startY, stepX, stepY)
    if !capture.ok {
        DebugLog("自动嬗变：装备栏区域截图失败")
        return itemPositions
    }

    Loop 3 {
        row := A_Index
        Loop 11 {
            if !isAutoTransmuting
                return itemPositions

            col := A_Index
            x := Round(startX + (col - 1) * stepX)
            y := Round(startY + (row - 1) * stepY)

            quality := ClassifyInventorySlotFromCapture(capture, x, y, stepX, stepY)
            if (targetQuality = "any")
                isTarget := (quality = "red" || quality = "yellow" || quality = "blue")
            else if (targetQuality = "redyellow")
                isTarget := (quality = "red" || quality = "yellow")
            else
                isTarget := (quality = targetQuality)

            if (isTarget)
                itemPositions.Push({x: x, y: y, row: row, col: col, quality: quality})
        }
    }

    DebugLog("自动嬗变：扫描完成，耗时 " (A_TickCount - scanStart) "ms，找到 "
        itemPositions.Length " 个目标物品(品质=" targetQuality ")")
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
 * 点击一个配方并执行「重塑/执行 → 接受」确认动作（黄装流程复用此套确认按钮）
 * @param {Object} recipe - 配方按钮坐标 {x, y}
 * @param {String} label - 日志标签
 * @returns {Boolean} 正常完成返回true，被取消返回false
 */
TransmuteApplyRecipe(recipe, label) {
    global isAutoTransmuting

    if !isAutoTransmuting
        return false

    MouseMove recipe.x, recipe.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击配方[" label "] x=" recipe.x " y=" recipe.y)
    if !TransmuteInterruptibleSleep(180)
        return false

    reforgeButton := ScalePoint(0.168, 0.793)
    MouseMove reforgeButton.x, reforgeButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击重塑/执行按钮 x=" reforgeButton.x " y=" reforgeButton.y)
    if !TransmuteInterruptibleSleep(450)
        return false

    acceptButton := ScalePoint(0.432, 0.560)
    MouseMove acceptButton.x, acceptButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变：点击接受按钮 x=" acceptButton.x " y=" acceptButton.y)
    return TransmuteInterruptibleSleep(1000)
}

/**
 * 对单个黄装(稀有)执行「添加词缀 → 升级至传奇 → 嬗变/重塑」三步配方，最后清除
 * 最终目标：黄装升为传奇(红)后再嬗变一次
 * 三个配方均复用 重塑/执行(0.168,0.793) → 接受(0.432,0.560) 这套确认动作
 * @param {Object} itemPos - 物品格坐标
 * @returns {Boolean} 正常完成返回true，被取消返回false
 */
TransmuteYellowItem(itemPos) {
    global isAutoTransmuting

    if !isAutoTransmuting
        return false

    MouseMove itemPos.x, itemPos.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "right"
    DebugLog("自动嬗变(黄装)：右键物品 行=" itemPos.row " 列=" itemPos.col " x=" itemPos.x " y=" itemPos.y)
    if !TransmuteInterruptibleSleep(250)
        return false

    ; 第一步：添加词缀（配方列表最上方）
    if !TransmuteApplyRecipe(ScalePoint(0.445, 0.233), "添加词缀")
        return false

    ; 第二步：升级至传奇（配方列表最下方）→ 物品此时变为传奇(红)
    if !TransmuteApplyRecipe(ScalePoint(0.445, 0.72), "升级至传奇")
        return false

    ; 第三步：嬗变/重塑（与红装流程相同的转化配方 0.445,0.380）
    if !TransmuteApplyRecipe(ScalePoint(0.445, 0.350), "嬗变/重塑")
        return false

    ; 最后清除魔盒
    clearButton := ScalePoint(0.168, 0.680)
    MouseMove clearButton.x, clearButton.y, 0
    if !TransmuteInterruptibleSleep(80)
        return false
    Click "left"
    DebugLog("自动嬗变(黄装)：点击清除按钮 x=" clearButton.x " y=" clearButton.y)
    return TransmuteInterruptibleSleep(350)
}

/**
 * 自动嬗变：扫描右下装备栏/背包33格，逐个右键物品、点击嬗变/配方、点击重塑、确认接受、等待1秒后清除
 * 勾选「升级黄装」后，黄装(稀有)走「添加词缀 → 升级至传奇」流程，红装(传奇/暗金)仍走重塑流程
 */
AutoTransmute(*) {
    global isRunning, isPaused, isAutoTransmuting, utilityControls

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

        upgradeYellow := (utilityControls.HasProp("upgradeYellow")
            && utilityControls.upgradeYellow.enable.Value = 1)
        targetQuality := upgradeYellow ? "redyellow" : "red"

        itemPositions := FindInventoryItems(targetQuality)
        if !isAutoTransmuting {
            cancelled := true
        } else {
            totalCount := itemPositions.Length
            if (totalCount = 0) {
                hint := upgradeYellow
                    ? "自动嬗变：装备栏/背包没有识别到传奇/暗金或稀有装备"
                    : "自动嬗变：装备栏/背包没有识别到暗金/传奇装备"
                UpdateStatus("未找到目标物品", hint)
                DebugLog("自动嬗变：未找到目标物品(品质=" targetQuality ")")
                return
            }

            DebugLog("自动嬗变：共识别到 " totalCount " 个目标物品(品质=" targetQuality ")")
            for index, itemPos in itemPositions {
                if !isAutoTransmuting {
                    cancelled := true
                    break
                }

                qualityLabel := (itemPos.quality = "yellow") ? "黄装升传奇" : "红装重塑"
                UpdateStatus("自动嬗变中", "正在处理第 " index "/" totalCount " 个物品[" qualityLabel "]（F3 取消）")

                ok := (itemPos.quality = "yellow")
                    ? TransmuteYellowItem(itemPos)
                    : TransmuteInventoryItem(itemPos)
                if ok
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