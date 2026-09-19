; ========== 血球（生命球）自动识别与血量测量 ==========
; 血球位于底部工具栏左侧：红色液体从球底向上填充，液面高度就是当前血量。
; 定位方式不需要手工拾取点位：血球所在区域按屏幕尺寸推算（2K 标定），
; 球心、球体半径与液面都在这个小窗口里自动定位，再用"圆缺面积占比"换算成
; 与游戏内一致的血量百分比，并识别"护盾遮挡"（球体变品红）状态。
; 注意：识别的是真实屏幕像素，所以检测时血球必须真的显示在屏幕上（游戏在前台）。
;
; 参数标定：用 screenShot.png(满血) / screenShot2.png(护盾) / lowblood.png(低血) / sample2.PNG 四张
; 2K 参考截图回归验证（tests/HealthGlobeTest.ahk），标定结果：
;   血球大约在屏幕宽/2-465、屏幕高-116 处，半径约 90，均按屏幕高度等比缩放（只作为搜索兜底）
;   液体像素  = 亮红(r>=62 且 r-g>=28 且 r-b>=24，并排除 b-g>20 的品红护盾色)
;               或 暗红(18<=r<=70 且相对饱和度>=0.75，用于把暗红液体与棕色 UI 背景区分开)
;   护盾像素  = r>=60 且 r-g>=35 且 b-g>=25 且 b>=45
;   满血/空血基准：液面在球顶下方 9px（按半径等比缩放）到球底上方 6px 之间（玻璃边缘与金属边框会各挡一点）

; ---------- 像素分类 ----------

/**
 * 亮红液体像素（血球被照亮的部分；排除品红的护盾色）
 */
IsLiquidBright(r, g, b) {
    return (r >= 62 && (r - g) >= 28 && (r - b) >= 24 && (b - g) <= 20)
}

/**
 * 暗红液体像素（血球下半部处于阴影中）
 * 用相对饱和度把暗红液体和棕色/青铜色 UI 背景区分开
 */
IsLiquidDark(r, g, b) {
    return (r >= 18 && r <= 70 && (r - g) * 4 >= r * 3 && (r - b) * 10 >= r * 7)
}

/**
 * 液体像素（亮红或暗红）
 */
IsLiquidPixel(r, g, b) {
    return IsLiquidBright(r, g, b) || IsLiquidDark(r, g, b)
}

/**
 * 护盾像素（护盾覆盖血球时球体呈品红色）
 */
IsShieldPixel(r, g, b) {
    return (r >= 60 && (r - g) >= 35 && (b - g) >= 25 && b >= 45)
}

/**
 * 读窗口内相对坐标像素，返回打包的 BGR（低8位=蓝，中8位=绿，高8位=红）
 */
ReadWindowPixel(cap, lx, ly) {
    if (lx < 0 || ly < 0 || lx >= cap.width || ly >= cap.height)
        return 0
    return NumGet(cap.bits, ly * cap.stride + lx * 3, "UInt")
}

/**
 * 判断窗口内某个像素是不是液体
 */
IsLiquidAt(cap, lx, ly) {
    px := ReadWindowPixel(cap, lx, ly)
    return IsLiquidPixel((px >> 16) & 0xFF, (px >> 8) & 0xFF, px & 0xFF)
}

/**
 * 由液面高度比例换算血量百分比（圆缺面积占比，与游戏内血球显示一致）
 * @param {Float} t - 液面高度占血球直径的比例（0=空 1=满）
 * @returns {Float} 0-1
 */
AreaFractionFromHeight(t) {
    t := Min(Max(t, 0.0), 1.0)
    x := 2 * t - 1                                    ; 液面相对球心的位置（-1=球底，1=球顶）
    return 0.5 + (x * Sqrt(Max(0.0, 1 - x * x)) + ASin(x)) / 3.141592653589793
}

/**
 * 统计某一行内液体像素数
 * @returns {Object} {hit, total}
 */
CountLiquidInRow(cap, row, colFrom, colTo, colStep, strongOnly) {
    hit := 0, total := 0
    col := colFrom
    while (col <= colTo) {
        px := ReadWindowPixel(cap, col, row)
        r := (px >> 16) & 0xFF, g := (px >> 8) & 0xFF, b := px & 0xFF
        if (strongOnly ? IsLiquidBright(r, g, b) : IsLiquidPixel(r, g, b))
            hit += 1
        total += 1
        col += colStep
    }
    return {hit: hit, total: total}
}

/**
 * 从球心下方往上找液面：液体占比不足一半的那一行就是液面下沿
 * @param cap - 截图对象
 * @param cxLocal, cyLocal - 球心的窗口内相对坐标
 * @param rad - 球体半径
 * @param strongOnly - 只认亮红液体（弱判定不可信时复核用）
 * @returns {Integer} 液面所在行（窗口内坐标）；整球都是液体时返回球顶
 */
ScanLiquidSurface(cap, cxLocal, cyLocal, rad, strongOnly) {
    row := cyLocal + Round(rad * 0.8)
    endRow := cyLocal - rad

    while (row > endRow) {
        dy := row - cyLocal
        halfChord := Sqrt(Max(0.0, rad * rad - dy * dy))
        span := Round(halfChord * 0.5)
        if (span >= 5) {
            colStep := Max(2, Round(span / 12))
            stat := CountLiquidInRow(cap, row, cxLocal - span, cxLocal + span, colStep, strongOnly)
            if (stat.total > 0 && stat.hit / stat.total < 0.5)
                return row + 2
        }
        row -= 2
    }

    return endRow
}

/**
 * 统计液面附近亮红液体占比：比值过低说明"液面"是被背景红光染出来的假象
 * @returns {Float} 0-1
 */
BrightLiquidShareBelow(cap, cxLocal, rowFrom, rowTo, cyLocal, rad) {
    hit := 0, total := 0
    row := rowFrom
    while (row < rowTo) {
        dy := row - cyLocal
        halfChord := Sqrt(Max(0.0, rad * rad - dy * dy))
        span := Round(halfChord * 0.5)
        if (span >= 5) {
            colStep := Max(2, Round(span / 10))
            stat := CountLiquidInRow(cap, row, cxLocal - span, cxLocal + span, colStep, true)
            hit += stat.hit
            total += stat.total
        }
        row += 2
    }
    return (total > 0) ? hit / total : 0.0
}

/**
 * 统计血球圆盘内护盾（品红）像素占比
 * @returns {Float} 0-1
 */
ShieldShareInOrb(cap, cxLocal, cyLocal, rad) {
    hit := 0, total := 0
    row := cyLocal - Round(rad * 0.85)
    endRow := cyLocal + Round(rad * 0.85)
    while (row <= endRow) {
        dy := row - cyLocal
        halfChord := Sqrt(Max(0.0, rad * rad - dy * dy))
        span := Round(halfChord * 0.55)
        if (span >= 5) {
            col := cxLocal - span
            while (col <= cxLocal + span) {
                px := ReadWindowPixel(cap, col, row)
                if (IsShieldPixel((px >> 16) & 0xFF, (px >> 8) & 0xFF, px & 0xFF))
                    hit += 1
                total += 1
                col += 2
            }
        }
        row += 3
    }
    return (total > 0) ? hit / total : 0.0
}

/**
 * 统计血球中线附近每一行的液体像素数
 * @returns {Object} {rowLiquid: Buffer, samplePerRow: Integer, fill: Float 液体占比}
 */
BuildLiquidRowProfile(cap, colFrom, colTo, colStep) {
    rowLiquid := Buffer(cap.height * 4, 0)
    samplePerRow := 0
    hitTotal := 0
    row := 0
    while (row < cap.height) {
        stat := CountLiquidInRow(cap, row, colFrom, colTo, colStep, false)
        NumPut("UInt", stat.hit, rowLiquid, row * 4)
        samplePerRow := stat.total
        hitTotal += stat.hit
        row += 1
    }

    total := samplePerRow * cap.height
    return {rowLiquid: rowLiquid, samplePerRow: samplePerRow
        , fill: (total > 0) ? hitTotal / total : 0.0}
}

/**
 * 液体底部：自下而上第一行"宽度足够"的液体（挡住血球边框上的红色描边）
 * @returns {Integer} 窗口内行号，没找到返回 -1
 */
FindLiquidBottomRow(rowLiquid, height, samplePerRow) {
    row := height - 1
    while (row >= 0) {
        if (NumGet(rowLiquid, row * 4, "UInt") >= 0.64 * samplePerRow)
            return row
        row -= 1
    }
    return -1
}

/**
 * 找最宽的一段液体：液体盖过球心时，最宽行就是球心所在行（赤道）
 * @returns {Integer} 窗口内行号（未找到返回 bottomRow）
 */
FindWidestLiquidRow(cap, centerCol, bottomRow) {
    widestRow := bottomRow, widestWidth := 0
    row := 0
    while (row <= bottomRow) {
        if (IsLiquidAt(cap, centerCol, row)) {
            lo := centerCol
            while (lo - 2 >= 0 && IsLiquidAt(cap, lo - 2, row))
                lo -= 2
            hi := centerCol
            while (hi + 2 < cap.width && IsLiquidAt(cap, hi + 2, row))
                hi += 2
            if (hi - lo > widestWidth) {
                widestWidth := hi - lo
                widestRow := row
            }
        }
        row += 2
    }
    return widestRow
}

/**
 * 横向球心：取液体底部若干行液体的左右边界中点（对球体明暗不均不敏感）
 * @returns {Integer} 窗口内列号
 */
FindOrbCenterCol(cap, centerCol, bottomRow, rad) {
    refLeft := Max(0, centerCol - Round(0.75 * rad))
    refRight := Min(cap.width - 1, centerCol + Round(0.75 * rad))
    minCol := cap.width, maxCol := -1

    row := Max(0, bottomRow - 8)
    while (row <= bottomRow) {
        col := refLeft
        while (col <= refRight) {
            px := ReadWindowPixel(cap, col, row)
            if (IsLiquidPixel((px >> 16) & 0xFF, (px >> 8) & 0xFF, px & 0xFF)) {
                minCol := Min(minCol, col)
                maxCol := Max(maxCol, col)
            }
            col += 1
        }
        row += 1
    }

    return (maxCol >= minCol) ? (minCol + maxCol) // 2 : centerCol
}

; ---------- 血球定位与血量读取 ----------

/**
 * 读取血球状态：自动定位血球 + 估算当前血量
 * @returns {Object} 状态对象
 *   state   : "ok" 读到血量 | "shield" 护盾遮挡 | "fail" 未识别到血球
 *   pct     : 血量百分比（state="ok" 时有效）
 *   shield  : 护盾像素占比
 *   cx, cy  : 识别出的血球圆心（屏幕坐标）
 *   rad     : 血球半径
 *   surface : 液面屏幕 Y 坐标；yB 为液体底部屏幕 Y 坐标
 *   reason  : 识别失败/降级原因
 */
ReadHealthGlobe() {
    ; 血球位置按屏幕尺寸推算（2K 标定：屏幕宽/2-465、屏幕高-116、半径 90），
    ; 球心与液面则在窗口内自动定位，所以不需要手工拾取点位
    scale := A_ScreenHeight / 1440
    rad := Max(24, Round(90 * scale))
    cx := Round(A_ScreenWidth / 2 - 465 * scale)
    cy := Round(A_ScreenHeight - 116 * scale)
    halfW := rad * 145 // 100

    ; 血球紧贴屏幕底部，2K 下窗口下沿会超出屏幕，这里把窗口压回屏幕内
    x := Min(Max(cx - halfW, 0), Max(0, A_ScreenWidth - halfW * 2 - 1))
    y := Min(Max(cy - halfW, 0), Max(0, A_ScreenHeight - halfW * 2 - 1))

    cap := CaptureScreenRegion(x, y, halfW * 2 + 1, halfW * 2 + 1)
    return AnalyzeHealthWindow(cap, rad, cx, cy)
}

/**
 * 分析血球窗口截图，得出状态与血量（纯计算，输入只有位图，便于单独验证）
 * @param {Object} cap - CaptureScreenRegion 返回的位图对象
 * @param {Integer} rad - 血球半径（2K 下为 90；窗口取球心 ±1.45r）
 * @param {Integer} priorCx, priorCy - 按屏幕尺寸推算的球心（屏幕坐标，用于选定分析中线）
 * @returns {Object} 同 ReadHealthGlobe
 */
AnalyzeHealthWindow(cap, rad := 90, priorCx := 0, priorCy := 0) {
    if (priorCx = 0 && priorCy = 0) {
        priorCx := cap.originX + cap.width // 2
        priorCy := cap.originY + cap.height // 2
    }

    result := {state: "fail", pct: -1, shield: 0.0, cx: priorCx, cy: priorCy, rad: rad
        , surface: 0, yB: 0, reason: ""}

    if (!cap.ok || cap.width < 10 || cap.height < 10) {
        result.reason := "屏幕截图失败"
        return result
    }

    scale := rad / 90
    w := cap.width, h := cap.height
    centerCol := Min(Max(priorCx - cap.originX, 0), w - 1)
    priorRow := Min(Max(priorCy - cap.originY, 0), h - 1)
    band := rad * 60 // 100

    ; --- 0) 护盾遮挡：护盾盖住血球时读不到真实血量，先用"按屏幕尺寸推算的球心"快速判定 ---
    shieldShare := ShieldShareInOrb(cap, centerCol, priorRow, rad)
    if (shieldShare > 0.3) {
        result.state := "shield"
        result.shield := shieldShare
        return result
    }

    ; --- 1) 液体轮廓：底部行、最宽行、横向球心 ---
    profile := BuildLiquidRowProfile(cap, Max(0, centerCol - band), Min(w - 1, centerCol + band)
        , Max(2, Round(rad / 22)))
    bottomRow := FindLiquidBottomRow(profile.rowLiquid, h, profile.samplePerRow)
    if (bottomRow < 0) {
        result.reason := "血球内没有检测到血液（窗口液体占比 "
            . Round(profile.fill * 100, 1) "%；取景球心 " priorCx "," priorCy "）"
        return result
    }

    widestRow := FindWidestLiquidRow(cap, centerCol, bottomRow)
    centerCol := FindOrbCenterCol(cap, centerCol, bottomRow, rad)
    cx := cap.originX + centerCol
    yB := cap.originY + bottomRow

    ; --- 2) 液面定位 ---
    ; 液体可见范围：上沿在球顶下方 topInset（玻璃边缘遮挡），下沿在球底上方 bottomInset（金属边框遮挡）
    topInset := Round(9 * scale)
    bottomInset := Round(6 * scale)
    visibleHeight := 2 * rad - topInset - bottomInset

    cyLocal := bottomRow - rad + bottomInset
    surfaceRow := ScanLiquidSurface(cap, centerCol, cyLocal, rad, false)

    ; 液面明显低于最宽行 → 液体没盖住球心，用液体底部推球心；
    ; 否则最宽行就是赤道，用最宽行定球心更准（满血时读数不会偏低）
    if ((widestRow - surfaceRow) >= Round(0.2 * rad)) {
        widestCenter := Min(Max(widestRow, (h // 2) - Round(0.3 * rad)), (h // 2) + Round(0.3 * rad))
        surfaceRow := ScanLiquidSurface(cap, centerCol, widestCenter, rad, false)
        cyLocal := widestCenter
    }

    ; 复核：液面附近缺少亮红液体时改用只认亮红的液面（更保守，宁可早喝药）
    brightShare := BrightLiquidShareBelow(cap, centerCol, surfaceRow
        , Min(bottomRow, surfaceRow + 14), cyLocal, rad)
    if (brightShare < 0.25) {
        surfaceRow := ScanLiquidSurface(cap, centerCol, cyLocal, rad, true)
        result.reason := "液面附近缺少亮红液体，已按保守方式估算"
    }

    surface := cap.originY + surfaceRow
    liquidBottomY := cyLocal + rad - bottomInset + cap.originY
    pct := AreaFractionFromHeight((liquidBottomY - surface) / visibleHeight) * 100

    result.state := "ok"
    result.pct := pct
    result.cx := cx
    result.cy := cap.originY + cyLocal
    result.surface := surface
    result.yB := yB

    ; 复核：护盾刚好盖住血球时同样读不到真实血量，交给"护盾策略"处理
    result.shield := ShieldShareInOrb(cap, centerCol, cyLocal, rad)
    if (result.shield > 0.3) {
        result.state := "shield"
        result.pct := -1
    }

    return result
}
