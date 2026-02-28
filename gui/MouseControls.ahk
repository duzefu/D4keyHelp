; ========== 鼠标控件 ==========
/**
 * 创建鼠标控件
 */
CreateMouseControls() {
    global myGui, mouseControls, skillModeNames, SKILL_MODE_CLICK

    mouseControls := {
        left: {
            enable: myGui.AddCheckbox("x135 y360 w60 h20", "启用"),
            interval: myGui.AddEdit("x205 y360 w60 h20", "80"),
            mode: myGui.AddDropDownList("x275 y360 w100 h120 Choose1", skillModeNames)
        },
        right: {
            enable: myGui.AddCheckbox("x135 y390 w60 h20", "启用"),
            interval: myGui.AddEdit("x205 y390 w60 h20", "300"),
            mode: myGui.AddDropDownList("x275 y390 w100 h120 Choose1", skillModeNames)
        }
    }
    myGui.AddText("x35 y360 w60 h20", "左键:")
    myGui.AddText("x35 y390 w60 h20", "右键:")

    ; 注册鼠标控件自动保存事件
    mouseControls.left.enable.OnEvent("Click", ScheduleAutoSave)
    mouseControls.left.interval.OnEvent("Change", ScheduleAutoSave)
    mouseControls.left.mode.OnEvent("Change", ScheduleAutoSave)
    mouseControls.right.enable.OnEvent("Click", ScheduleAutoSave)
    mouseControls.right.interval.OnEvent("Change", ScheduleAutoSave)
    mouseControls.right.mode.OnEvent("Change", ScheduleAutoSave)
}

/**
 * 创建功能键控件
 */
CreateUtilityControls() {
    global myGui, utilityControls, mouseAutoMove, pauseOnClick, compassControl

    myGui.AddText("x35 y425 w60 h20", "翻滚:")
    myGui.AddText("x35 y455 w60 h20", "喝药:")
    myGui.AddText("x35 y485 w60 h20", "强移:")

    utilityControls := {
        dodge: {
            key: myGui.AddText("x95 y425 w35 h20", "空格"),
            enable: myGui.AddCheckbox("x135 y425 w60 h20", "启用"),
            interval: myGui.AddEdit("x205 y425 w60 h20", "1000")
        },
        potion: {
            key: myGui.AddHotkey("x95 y455 w35 h20", "q"),
            enable: myGui.AddCheckbox("x135 y455 w60 h20", "启用"),
            interval: myGui.AddEdit("x205 y455 w60 h20", "15000")
        },
        forceMove: {
            key: myGui.AddHotkey("x95 y485 w35 h20", "``"),
            enable: myGui.AddCheckbox("x135 y485 w60 h20", "启用"),
            interval: myGui.AddEdit("x205 y485 w60 h20", "50")
        }
    }

    ; 添加鼠标自动移动控件
    mouseAutoMove := {
        enable: myGui.AddCheckbox("x295 y485 w140 h20", "鼠标自动移动"),
        interval: myGui.AddEdit("x435 y485 w30 h20", "1000")
    }
    mouseAutoMove.enable.OnEvent("Click", ToggleMouseAutoMove)
    mouseAutoMove.enable.OnEvent("Click", ScheduleAutoSave)
    mouseAutoMove.interval.OnEvent("Change", ScheduleAutoSave)

    ; 添加鼠标点击暂停宏控件
    pauseOnClick := {
        enable: myGui.AddCheckbox("x295 y455 w140 h20", "鼠标点击时暂停宏"),
        interval: myGui.AddEdit("x435 y455 w30 h20", "2000")
    }
    pauseOnClick.enable.OnEvent("Click", TogglePauseOnClick)
    pauseOnClick.enable.OnEvent("Click", ScheduleAutoSave)
    pauseOnClick.interval.OnEvent("Change", ScheduleAutoSave)

    ; 添加罗盘专用控件
    compassControl := {
        enable: myGui.AddCheckbox("x295 y425 w100 h20", "罗盘专用"),
        interval: myGui.AddEdit("x405 y425 w60 h20", "65000")
    }
    compassControl.enable.OnEvent("Click", ToggleCompass)
    compassControl.enable.OnEvent("Click", ScheduleAutoSave)
    compassControl.interval.OnEvent("Change", ScheduleAutoSave)

    ; 注册功能键控件自动保存事件
    utilityControls.dodge.enable.OnEvent("Click", ScheduleAutoSave)
    utilityControls.dodge.interval.OnEvent("Change", ScheduleAutoSave)
    utilityControls.potion.key.OnEvent("Change", ScheduleAutoSave)
    utilityControls.potion.enable.OnEvent("Click", ScheduleAutoSave)
    utilityControls.potion.interval.OnEvent("Change", ScheduleAutoSave)
    utilityControls.forceMove.key.OnEvent("Change", ScheduleAutoSave)
    utilityControls.forceMove.enable.OnEvent("Click", ScheduleAutoSave)
    utilityControls.forceMove.interval.OnEvent("Change", ScheduleAutoSave)
}