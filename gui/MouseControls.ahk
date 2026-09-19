; ========== 额外设置控件（仿D3keyHelper风格） ==========
/**
 * 创建额外设置区域
 * 包含：Shift开关、调试日志、翻滚、喝药（含血量检测）、强移、鼠标自动移动、
 *       鼠标点击暂停、罗盘专用、自动嬗变、血量检测与血球检测点
 */
CreateExtraSettings() {
    global myGui, utilityControls, mouseAutoMove, pauseOnClick, compassControl
    global healthStatusText

    ; Row 1: 按住Shift + 调试日志
    shiftCheck := myGui.AddCheckbox("x35 y420 w120 h22" MUI_CardBg, "按住 Shift")
    shiftCheck.OnEvent("Click", ToggleShift)
    debugLogCheck := myGui.AddCheckbox("x290 y420 w100 h22 Checked" MUI_CardBg, "调试日志")
    debugLogCheck.ToolTip := "关闭后不再写日志文件；开启后可在 settings.ini 里把 DebugLogVerbose 设为 1 记录每次按键明细"
    clearLogButton := ModernButton(myGui, 400, 414, 110, 30, "清理日志", "secondary", {radius: 8, fontSize: 9})

    ; Row 2: 翻滚
    myGui.AddText("x35 y454 w55 h22 right" MUI_CardBg, "翻滚：")
    dodgeKeyLabel := myGui.AddText("x100 y454 w50 h22" MUI_CardBg, "空格")
    dodgeEnable := myGui.AddCheckbox("x165 y454 w70 h22" MUI_CardBg, "启用")
    myGui.AddText("x250 y454 w100 h22" MUI_CardBg, "间隔 (ms)：")
    dodgeIntervalEdit := myGui.AddEdit("x355 y452 w90 Number", "1000")
    dodgeIntervalUpDown := myGui.AddUpDown("0x80 Range100-60000", 1000)

    ; Row 3: 喝药（含血量检测）
    myGui.AddText("x35 y488 w55 h22 right" MUI_CardBg, "喝药：")
    potionKey := myGui.AddHotkey("x100 y486 w50 h22", "q")
    potionEnable := myGui.AddCheckbox("x165 y488 w70 h22" MUI_CardBg, "启用")
    myGui.AddText("x250 y488 w100 h22" MUI_CardBg, "间隔 (ms)：")
    potionIntervalEdit := myGui.AddEdit("x355 y486 w90 Number", "15000")
    potionIntervalUpDown := myGui.AddUpDown("0x80 Range100-60000", 15000)
    healthCheckEnable := myGui.AddCheckbox("x455 y488 w85 h22" MUI_CardBg, "血量检测")
    healthCheckEnable.ToolTip := "按血球液面自动判断血量，低于阈值才喝药；建议把喝药间隔改成 1000~2000ms"
    healthShieldSafeCheck := myGui.AddCheckbox("x548 y488 w140 h22 Checked" MUI_CardBg, "护盾遮挡时不喝药")
    healthShieldSafeCheck.ToolTip := "护盾盖住血球时读不出血量：勾选=视为安全跳过；取消=照常喝药（适合常驻护盾的构筑）"

    ; Row 4: 强移
    myGui.AddText("x35 y522 w55 h22 right" MUI_CardBg, "强移：")
    forceMoveKey := myGui.AddHotkey("x100 y520 w50 h22", "``")
    forceMoveEnable := myGui.AddCheckbox("x165 y522 w70 h22" MUI_CardBg, "启用")
    myGui.AddText("x250 y522 w100 h22" MUI_CardBg, "间隔 (ms)：")
    forceMoveIntervalEdit := myGui.AddEdit("x355 y520 w90 Number", "50")
    forceMoveIntervalUpDown := myGui.AddUpDown("0x80 Range20-60000", 50)

    ; Row 5: 鼠标自动移动 + 鼠标点击暂停
    mouseAutoMoveEnable := myGui.AddCheckbox("x35 y556 w135 h22" MUI_CardBg, "鼠标自动移动")
    mouseAutoMoveIntervalEdit := myGui.AddEdit("x180 y554 w70 Number", "1000")
    mouseAutoMoveUpDown := myGui.AddUpDown("0x80 Range100-60000", 1000)

    pauseOnClickEnable := myGui.AddCheckbox("x290 y556 w160 h22" MUI_CardBg, "鼠标点击时暂停宏")
    pauseOnClickIntervalEdit := myGui.AddEdit("x460 y554 w80 Number", "3000")
    pauseOnClickUpDown := myGui.AddUpDown("0x80 Range500-60000", 3000)

    ; Row 6: 罗盘专用 + 自动嬗变
    compassEnable := myGui.AddCheckbox("x35 y590 w120 h22" MUI_CardBg, "罗盘专用")
    myGui.AddText("x165 y590 w100 h22" MUI_CardBg, "间隔 (ms)：")
    compassIntervalEdit := myGui.AddEdit("x270 y588 w90 Number", "65000")
    compassUpDown := myGui.AddUpDown("0x80 Range1000-600000", 65000)
    upgradeYellowEnable := myGui.AddCheckbox("x382 y590 w98 h22" MUI_CardBg, "升级黄装")
    ModernButton(myGui, 482, 584, 120, 30, "自动嬗变 (F3)", "soft", {radius: 8, fontSize: 9}).OnEvent("Click", AutoTransmute)
    ModernButton(myGui, 608, 584, 30, 30, "?", "secondary", {radius: 15, fontSize: 10}).OnEvent("Click", OpenTransmuteHelp)

    ; Row 7: 血量阈值 + 检测血球
    myGui.AddText("x35 y624 w95 h22 right" MUI_CardBg, "血量阈值：")
    healthThresholdEdit := myGui.AddEdit("x138 y622 w50 Number", "50")
    healthThresholdEdit.ToolTip := "血量低于该百分比才喝药（血球液面高度换算，50 即球心位置）"
    healthThresholdUpDown := myGui.AddUpDown("0x80 Range5-95", 50)
    myGui.AddText("x192 y624 w20 h22" MUI_CardBg, "%")
    healthTestButton := ModernButton(myGui, 220, 618, 100, 30, "检测血球", "secondary", {radius: 8, fontSize: 9})
    healthTestButton.ToolTip := "点后 3 秒识别血球（留时间切回游戏）：球心位置、当前血量与判定结果显示在下方状态栏"
    healthStatusText := myGui.AddText("x330 y624 w355 h22" MUI_CardBg, "未检测（点「检测血球」后切回游戏）")
    healthStatusText.ToolTip := "最近一次识别到的血量读数（宏运行中会自动刷新）"

    ; 存储控件引用
    utilityControls := {
        dodge: {
            key: dodgeKeyLabel,
            enable: dodgeEnable,
            interval: dodgeIntervalEdit
        },
        potion: {
            key: potionKey,
            enable: potionEnable,
            interval: potionIntervalEdit
        },
        forceMove: {
            key: forceMoveKey,
            enable: forceMoveEnable,
            interval: forceMoveIntervalEdit
        },
        upgradeYellow: {
            enable: upgradeYellowEnable
        }
    }

    mouseAutoMove := {
        enable: mouseAutoMoveEnable,
        interval: mouseAutoMoveIntervalEdit
    }

    pauseOnClick := {
        enable: pauseOnClickEnable,
        interval: pauseOnClickIntervalEdit
    }

    compassControl := {
        enable: compassEnable,
        interval: compassIntervalEdit
    }

    ; 新增控件挂在 utilityControls 上，供保存/加载使用
    utilityControls.healthCheck := {
        enable: healthCheckEnable,
        threshold: healthThresholdEdit,
        shieldSafe: healthShieldSafeCheck
    }
    utilityControls.debugLog := debugLogCheck

    ; 注册事件
    mouseAutoMoveEnable.OnEvent("Click", ToggleMouseAutoMove)
    mouseAutoMoveEnable.OnEvent("Click", ScheduleAutoSave)
    mouseAutoMoveIntervalEdit.OnEvent("Change", ScheduleAutoSave)

    pauseOnClickEnable.OnEvent("Click", TogglePauseOnClick)
    pauseOnClickEnable.OnEvent("Click", ScheduleAutoSave)
    pauseOnClickIntervalEdit.OnEvent("Change", ScheduleAutoSave)

    compassEnable.OnEvent("Click", ToggleCompass)
    compassEnable.OnEvent("Click", ScheduleAutoSave)
    compassIntervalEdit.OnEvent("Change", ScheduleAutoSave)

    ; 功能键控件自动保存事件
    dodgeEnable.OnEvent("Click", ScheduleAutoSave)
    dodgeIntervalEdit.OnEvent("Change", ScheduleAutoSave)
    potionKey.OnEvent("Change", ScheduleAutoSave)
    potionEnable.OnEvent("Click", ScheduleAutoSave)
    potionIntervalEdit.OnEvent("Change", ScheduleAutoSave)
    forceMoveKey.OnEvent("Change", ScheduleAutoSave)
    forceMoveEnable.OnEvent("Click", ScheduleAutoSave)
    forceMoveIntervalEdit.OnEvent("Change", ScheduleAutoSave)

    upgradeYellowEnable.OnEvent("Click", ScheduleAutoSave)

    ; 新增功能事件
    debugLogCheck.OnEvent("Click", OnDebugLogToggled)
    clearLogButton.OnEvent("Click", OnClearLogs)
    healthCheckEnable.OnEvent("Click", OnHealthCheckToggled)
    healthCheckEnable.OnEvent("Click", ScheduleAutoSave)
    healthThresholdEdit.OnEvent("Change", ScheduleAutoSave)
    healthShieldSafeCheck.OnEvent("Click", ScheduleAutoSave)
    healthTestButton.OnEvent("Click", TestHealthDetect)
}

/**
 * 切换调试日志开关
 */
OnDebugLogToggled(ctrl, *) {
    global statusBar

    enabled := SetLogEnabled(ctrl.Value)
    if (statusBar != "")
        statusBar.Text := "调试日志已" (enabled ? "开启" : "关闭")
}

/**
 * 清理日志文件
 */
OnClearLogs(*) {
    global statusBar

    freed := ClearLogs()
    if (statusBar != "")
        statusBar.Text := "日志已清理，释放 " Round(freed / 1024, 1) " KB"
}

/**
 * 切换血量检测开关
 */
OnHealthCheckToggled(ctrl, *) {
    global healthCheckEnabled, statusBar, utilityControls

    healthCheckEnabled := (ctrl.Value = 1)

    if (!healthCheckEnabled) {
        if (statusBar != "")
            statusBar.Text := "血量检测已关闭（回到按间隔定时喝药）"
        return
    }

    ; 开启时把过慢的喝药间隔调小：否则血量掉到阈值下方也要等很久才喝
    interval := utilityControls.potion.interval.Value
    if (interval > 5000) {
        utilityControls.potion.interval.Value := 1500
        DebugLog("血量检测开启，喝药间隔由 " interval "ms 调整为 1500ms")
        if (statusBar != "")
            statusBar.Text := "血量检测已开启：喝药间隔已从 " interval "ms 调整为 1500ms"
        return
    }

    if (statusBar != "")
        statusBar.Text := "血量检测已开启，点「检测血球」可确认识别结果"
}

/**
 * 打开GitHub README查看自动嬗变说明
 */
OpenTransmuteHelp(*) {
    Run "https://github.com/duzefu/D4keyHelp#readme"
}
