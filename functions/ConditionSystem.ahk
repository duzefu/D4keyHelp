; ========== 条件检测系统 ==========
; 条件喝药：读血球液面估算当前血量，只在低于设定阈值时按喝药键
; 血球的定位与血量换算见 functions/HealthGlobe.ahk

; ---------- 读取（带缓存） ----------

/**
 * 读取血球状态
 * 默认带 HEALTH_CACHE_MS 缓存：喝药间隔被设得很小时也不会反复截图和刷新界面
 * @param {Boolean} force - true 时忽略缓存重新识别（界面按钮用）
 * @returns {Object} ReadHealthGlobe 的返回值
 */
ReadHealthCached(force := false) {
    global healthCacheTick, healthCacheState, healthLastState, healthLastPct

    if (!force && healthCacheState != "" && A_TickCount - healthCacheTick < HEALTH_CACHE_MS)
        return healthCacheState

    state := ReadHealthGlobe()
    healthCacheTick := A_TickCount
    healthCacheState := state
    healthLastState := state.state
    healthLastPct := state.pct
    UpdateHealthStatusText(force)

    return state
}

; ---------- 判定 ----------

/**
 * 判断是否应该喝药
 * 未识别到血球时返回 true，回退成按间隔定时喝药（与原行为一致）
 * @returns {Boolean}
 */
ShouldDrinkPotion() {
    global utilityControls

    state := ReadHealthCached()

    if (state.state = "fail") {
        DebugLog("血量识别失败，本次按定时喝药: " state.reason)
        return true
    }

    if (state.state = "shield") {
        if (utilityControls.healthCheck.shieldSafe.Value = 1) {
            DebugLog("护盾遮挡血球，跳过喝药（护盾占比 " Round(state.shield * 100) "%）", 2)
            return false
        }
        DebugLog("护盾遮挡血球，按设置照常喝药")
        return true
    }

    threshold := utilityControls.healthCheck.threshold.Value
    DebugLog("血量读数 " Round(state.pct) "% / 阈值 " threshold "%", 2)
    return (state.pct < threshold)
}

; ---------- 界面动作 ----------

/**
 * 检测血球（界面按钮）：3 秒后截图，给用户切回游戏的时间
 * 血球必须真的显示在屏幕上才能读数，所以不能在宏窗口挡着的时候检测
 */
TestHealthDetect(*) {
    global statusBar

    statusBar.Text := "3 秒后检测血球，请切回游戏并让血球露出来…"
    SetTimer DetectHealthGlobeDelayed, -3000
}

/**
 * 延时检测血球的定时器回调
 */
DetectHealthGlobeDelayed() {
    global statusBar, utilityControls

    if !WinActive("ahk_class Diablo IV Main Window Class") {
        statusBar.Text := "检测中断：暗黑4 窗口不在前台，血球被别的窗口挡住时读不到"
        DebugLog("血球检测中断：暗黑4 窗口不在前台")
        return
    }

    state := ReadHealthCached(true)
    threshold := utilityControls.healthCheck.threshold.Value

    switch state.state {
        case "ok":
            msg := "血球已识别：球心(" state.cx "," state.cy ") 半径" state.rad
                . " · 当前血量≈" Round(state.pct) "%（阈值 " threshold "% → "
                . (state.pct < threshold ? "会喝药" : "不喝药") "）"
        case "shield":
            msg := "血球被护盾遮挡（护盾占比 " Round(state.shield * 100) "%），读不到血量"
        default:
            msg := "未识别到血球：" state.reason
    }

    statusBar.Text := msg
    DebugLog("血球检测 - " msg)
}

/**
 * 刷新界面上的血量显示
 * @param {Boolean} force - true 时忽略节流立即刷新（按钮点击、状态变化时用）
 */
UpdateHealthStatusText(force := false) {
    global healthStatusText, healthLastState, healthLastPct
    global healthUiTick, healthUiState, utilityControls

    if (healthStatusText = "")
        return

    now := A_TickCount
    if (!force && healthLastState = healthUiState && now - healthUiTick < 1000)
        return
    healthUiTick := now
    healthUiState := healthLastState

    switch healthLastState {
        case "ok":
            healthStatusText.Text := "血量 " Round(healthLastPct) "%（阈值 "
                . utilityControls.healthCheck.threshold.Value "%）"
        case "shield":
            healthStatusText.Text := "护盾遮挡血球，读不到血量"
        case "fail":
            healthStatusText.Text := "未识别到血球"
        default:
            healthStatusText.Text := "未检测（点「检测血球」后切回游戏）"
    }
}
