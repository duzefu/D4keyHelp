; ========== 额外设置控件（仿D3keyHelper风格） ==========
/**
 * 创建额外设置区域
 * 包含：Shift开关、翻滚、喝药、强移、鼠标自动移动、鼠标点击暂停、罗盘专用
 */
CreateExtraSettings() {
    global myGui, utilityControls, mouseAutoMove, pauseOnClick, compassControl

    ; Row 1: 按住Shift
    myGui.AddCheckbox("x35 y420 w120 h22" MUI_CardBg, "按住 Shift").OnEvent("Click", ToggleShift)

    ; Row 2: 翻滚
    myGui.AddText("x35 y454 w55 h22 right" MUI_CardBg, "翻滚：")
    dodgeKeyLabel := myGui.AddText("x100 y454 w50 h22" MUI_CardBg, "空格")
    dodgeEnable := myGui.AddCheckbox("x165 y454 w70 h22" MUI_CardBg, "启用")
    myGui.AddText("x250 y454 w100 h22" MUI_CardBg, "间隔 (ms)：")
    dodgeIntervalEdit := myGui.AddEdit("x355 y452 w90 Number", "1000")
    dodgeIntervalUpDown := myGui.AddUpDown("0x80 Range100-60000", 1000)

    ; Row 3: 喝药
    myGui.AddText("x35 y488 w55 h22 right" MUI_CardBg, "喝药：")
    potionKey := myGui.AddHotkey("x100 y486 w50 h22", "q")
    potionEnable := myGui.AddCheckbox("x165 y488 w70 h22" MUI_CardBg, "启用")
    myGui.AddText("x250 y488 w100 h22" MUI_CardBg, "间隔 (ms)：")
    potionIntervalEdit := myGui.AddEdit("x355 y486 w90 Number", "15000")
    potionIntervalUpDown := myGui.AddUpDown("0x80 Range100-60000", 15000)

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
}

/**
 * 打开GitHub README查看自动嬗变说明
 */
OpenTransmuteHelp(*) {
    Run "https://github.com/duzefu/D4keyHelp#readme"
}