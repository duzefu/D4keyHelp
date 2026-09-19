; ========== 条件检测系统 ==========
; 条件喝药：检测血球上某个点的颜色，判断血量是否低于阈值

; ---------- 通用取色工具 ----------

/**
 * 取点周围十字 5 点的平均颜色（单点容易被描边/光效干扰）
 * @param {Integer} x - 屏幕X坐标
 * @param {Integer} y - 屏幕Y坐标
 * @param {Integer} radius - 采样偏移像素
 * @returns {Object} {r, g, b}，取值失败返回全 0
 */
SamplePointColor(x, y, radius := 2) {
    offsets := [[0, 0], [radius, 0], [-radius, 0], [0, radius], [0, -radius]]
    sumR := 0, sumG := 0, sumB := 0

    try {
        for off in offsets {
            color := PixelGetColor(x + off[1], y + off[2])
            sumR += (color >> 16) & 0xFF
            sumG += (color >> 8) & 0xFF
            sumB += color & 0xFF
        }
    } catch as err {
        DebugLog("取色失败: " err.Message)
        return {r: 0, g: 0, b: 0}
    }

    count := offsets.Length
    return {r: Round(sumR / count), g: Round(sumG / count), b: Round(sumB / count)}
}

/**
 * 颜色转 6 位十六进制字符串（用于写入 ini）
 */
ColorToHex(rgb) {
    return Format("{:02X}{:02X}{:02X}", rgb.r, rgb.g, rgb.b)
}

/**
 * 6 位十六进制字符串转颜色（读取 ini 用），非法值返回全 0
 */
ColorFromHex(hex) {
    hex := Trim(hex, " `t")
    if (StrLen(hex) != 6 || !RegExMatch(hex, "^[0-9A-Fa-f]{6}$"))
        return {r: 0, g: 0, b: 0}

    return {
        r: Integer("0x" SubStr(hex, 1, 2)),
        g: Integer("0x" SubStr(hex, 3, 2)),
        b: Integer("0x" SubStr(hex, 5, 2))
    }
}

/**
 * 两个颜色的平均通道差（0-255）
 */
ColorDistance(a, b) {
    return (Abs(a.r - b.r) + Abs(a.g - b.g) + Abs(a.b - b.b)) / 3
}

/**
 * 是否为"红色系"（血球填充区的特征色）
 */
IsReddish(rgb) {
    return (rgb.r >= 70 && rgb.r >= rgb.g + 25 && rgb.r >= rgb.b + 25)
}

; ---------- 条件喝药 ----------

/**
 * 判断是否应该喝药（血量低于所取位置的高度）
 * 未设置检测点时始终返回 true，保持原有定时喝药行为
 * @returns {Boolean}
 */
ShouldDrinkPotion() {
    global healthPoint, HEALTH_MATCH_TOLERANCE

    if (!healthPoint.ready)
        return true

    rgb := SamplePointColor(healthPoint.x, healthPoint.y)
    diff := ColorDistance(rgb, healthPoint.color)
    return (diff > HEALTH_MATCH_TOLERANCE)
}

/**
 * 开始拾取血球检测点（3 秒后取当前鼠标位置）
 */
PickHealthPoint(*) {
    global statusBar
    statusBar.Text := "3 秒后拾取血球位置：请把鼠标移到血球上「想开始喝药的血量高度」，之后保持不动"
    SetTimer CaptureHealthPoint, -3000
}

/**
 * 拾取血球检测点并保存（延时定时器回调）
 */
CaptureHealthPoint() {
    global statusBar, healthPoint
    if (statusBar = "")
        return

    MouseGetPos &x, &y
    rgb := SamplePointColor(x, y)
    healthPoint := {x: x, y: y, color: rgb, ready: true}
    UpdateHealthPointText()

    if IsReddish(rgb) {
        statusBar.Text := "血球检测点已拾取: " x "," y " 颜色#" ColorToHex(rgb)
            . " - 该点颜色偏离即判定血量低于此高度并喝药"
        DebugLog("血球检测点已拾取: x=" x " y=" y " 颜色#" ColorToHex(rgb))
    } else {
        statusBar.Text := "⚠ 该点当前不是红色填充区（可能血量已低于所选高度或点选有误），建议满血时重新拾取"
        DebugLog("血球检测点拾取异常: x=" x " y=" y " 颜色#" ColorToHex(rgb) "（非红色系）")
    }

    SaveSettings()
}

/**
 * 刷新界面上血球检测点的显示文本
 */
UpdateHealthPointText() {
    global healthPointText, healthPoint
    if (healthPointText = "")
        return

    if (healthPoint.ready)
        healthPointText.Text := "x=" healthPoint.x ", y=" healthPoint.y
            . "  #" ColorToHex(healthPoint.color)
    else
        healthPointText.Text := "未拾取（未拾取时按原定时喝药）"
}

/**
 * 测试取色：把血球检测点当前颜色与基准色的差异显示到状态栏，并写入日志
 * 用于确认检测点是否落在血球填充区、阈值是否合适
 */
TestColorSampling(*) {
    global statusBar, healthPoint, HEALTH_MATCH_TOLERANCE

    if (!healthPoint.ready) {
        statusBar.Text := "尚未拾取血球检测点：请先点「拾取血球位置」"
        return
    }

    rgb := SamplePointColor(healthPoint.x, healthPoint.y)
    diff := Round(ColorDistance(rgb, healthPoint.color))
    drink := ShouldDrinkPotion()

    summary := "血球检测点(" healthPoint.x "," healthPoint.y ") 当前#" ColorToHex(rgb)
        . " 基准#" ColorToHex(healthPoint.color) " 差异=" diff
        . "/" HEALTH_MATCH_TOLERANCE " → " (drink ? "判定需喝药" : "判定血量充足")

    statusBar.Text := summary
    DebugLog("取色测试 - " summary)
}
