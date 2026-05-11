; ========== 额外设置控件（仿D3keyHelper风格） ==========
/**
 * 创建额外设置区域
 * 包含：Shift开关、翻滚、喝药、强移、鼠标自动移动、鼠标点击暂停、罗盘专用
 */
CreateExtraSettings() {
    global myGui, utilityControls, mouseAutoMove, pauseOnClick, compassControl

    ; Row 1: 按住Shift
    myGui.AddCheckbox("x35 y380 w120 h22", "按住 Shift").OnEvent("Click", ToggleShift)

    ; Row 2: 翻滚
    myGui.AddText("x35 y414 w55 h22 right", "翻滚：")
    dodgeKeyLabel := myGui.AddText("x100 y414 w50 h22", "空格")
    dodgeEnable := myGui.AddCheckbox("x165 y414 w70 h22", "启用")
    myGui.AddText("x250 y414 w100 h22", "间隔 (ms)：")
    dodgeIntervalEdit := myGui.AddEdit("x355 y412 w90 Number", "1000")
    dodgeIntervalUpDown := myGui.AddUpDown("Range100-60000", 1000)

    ; Row 3: 喝药
    myGui.AddText("x35 y448 w55 h22 right", "喝药：")
    potionKey := myGui.AddHotkey("x100 y446 w50 h22", "q")
    potionEnable := myGui.AddCheckbox("x165 y448 w70 h22", "启用")
    myGui.AddText("x250 y448 w100 h22", "间隔 (ms)：")
    potionIntervalEdit := myGui.AddEdit("x355 y446 w90 Number", "15000")
    potionIntervalUpDown := myGui.AddUpDown("Range1000-60000", 15000)

    ; Row 4: 强移
    myGui.AddText("x35 y482 w55 h22 right", "强移：")
    forceMoveKey := myGui.AddHotkey("x100 y480 w50 h22", "``")
    forceMoveEnable := myGui.AddCheckbox("x165 y482 w70 h22", "启用")
    myGui.AddText("x250 y482 w100 h22", "间隔 (ms)：")
    forceMoveIntervalEdit := myGui.AddEdit("x355 y480 w90 Number", "50")
    forceMoveIntervalUpDown := myGui.AddUpDown("Range20-60000", 50)

    ; Row 5: 鼠标自动移动 + 鼠标点击暂停
    mouseAutoMoveEnable := myGui.AddCheckbox("x35 y516 w135 h22", "鼠标自动移动")
    mouseAutoMoveIntervalEdit := myGui.AddEdit("x180 y514 w70 Number", "1000")
    mouseAutoMoveUpDown := myGui.AddUpDown("Range100-60000", 1000)

    pauseOnClickEnable := myGui.AddCheckbox("x290 y516 w160 h22", "鼠标点击时暂停宏")
    pauseOnClickIntervalEdit := myGui.AddEdit("x460 y514 w80 Number", "3000")
    pauseOnClickUpDown := myGui.AddUpDown("Range500-60000", 3000)

    ; Row 6: 罗盘专用
    compassEnable := myGui.AddCheckbox("x35 y550 w120 h22", "罗盘专用")
    myGui.AddText("x165 y550 w100 h22", "间隔 (ms)：")
    compassIntervalEdit := myGui.AddEdit("x270 y548 w90 Number", "65000")
    compassUpDown := myGui.AddUpDown("Range1000-600000", 65000)

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
}