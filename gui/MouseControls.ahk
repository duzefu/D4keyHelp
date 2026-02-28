; ========== 额外设置控件（仿D3keyHelper风格） ==========
/**
 * 创建额外设置区域
 * 包含：Shift开关、翻滚、喝药、强移、鼠标自动移动、鼠标点击暂停、罗盘专用
 */
CreateExtraSettings() {
    global myGui, utilityControls, mouseAutoMove, pauseOnClick, compassControl

    ; ========== 额外设置 GroupBox ==========
    myGui.AddGroupBox("x15 y305 w610 h190", "额外设置")

    ; Row 1: 按住Shift
    myGui.AddCheckbox("x30 y327 w100 h20", "按住Shift").OnEvent("Click", ToggleShift)

    ; Row 2: 翻滚
    myGui.AddText("x30 y355 w50 h20 right", "翻滚：")
    dodgeKeyLabel := myGui.AddText("x85 y355 w40 h20", "空格")
    dodgeEnable := myGui.AddCheckbox("x135 y355 w60 h20", "启用")
    myGui.AddText("x200 y355 w90 h20", "间隔(毫秒)：")
    dodgeIntervalEdit := myGui.AddEdit("x295 y353 w70 Number", "1000")
    dodgeIntervalUpDown := myGui.AddUpDown("Range100-60000", 1000)

    ; Row 3: 喝药
    myGui.AddText("x30 y381 w50 h20 right", "喝药：")
    potionKey := myGui.AddHotkey("x85 y379 w40 h20", "q")
    potionEnable := myGui.AddCheckbox("x135 y381 w60 h20", "启用")
    myGui.AddText("x200 y381 w90 h20", "间隔(毫秒)：")
    potionIntervalEdit := myGui.AddEdit("x295 y379 w70 Number", "15000")
    potionIntervalUpDown := myGui.AddUpDown("Range1000-60000", 15000)

    ; Row 4: 强移
    myGui.AddText("x30 y407 w50 h20 right", "强移：")
    forceMoveKey := myGui.AddHotkey("x85 y405 w40 h20", "``")
    forceMoveEnable := myGui.AddCheckbox("x135 y407 w60 h20", "启用")
    myGui.AddText("x200 y407 w90 h20", "间隔(毫秒)：")
    forceMoveIntervalEdit := myGui.AddEdit("x295 y405 w70 Number", "50")
    forceMoveIntervalUpDown := myGui.AddUpDown("Range20-60000", 50)

    ; Row 5: 鼠标自动移动 + 鼠标点击暂停
    mouseAutoMoveEnable := myGui.AddCheckbox("x30 y433 w120 h20", "鼠标自动移动")
    mouseAutoMoveIntervalEdit := myGui.AddEdit("x155 y431 w50 Number", "1000")
    mouseAutoMoveUpDown := myGui.AddUpDown("Range100-60000", 1000)

    pauseOnClickEnable := myGui.AddCheckbox("x240 y433 w140 h20", "鼠标点击时暂停宏")
    pauseOnClickIntervalEdit := myGui.AddEdit("x390 y431 w60 Number", "3000")
    pauseOnClickUpDown := myGui.AddUpDown("Range500-60000", 3000)

    ; Row 6: 罗盘专用
    compassEnable := myGui.AddCheckbox("x30 y459 w100 h20", "罗盘专用")
    compassIntervalEdit := myGui.AddEdit("x135 y457 w70 Number", "65000")
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