; ========== 鼠标控件 ==========
/**
 * 创建鼠标控件
 */
CreateMouseControls() {
    global myGui, mouseControls, skillModeNames, SKILL_MODE_CLICK

    mouseControls := {
        left: {
            enable: myGui.AddCheckbox("x130 y345 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y345 w60 h20", "80"),
            mode: myGui.AddDropDownList("x270 y345 w100 h120 Choose1", skillModeNames)
        },
        right: {
            enable: myGui.AddCheckbox("x130 y375 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y375 w60 h20", "300"),
            mode: myGui.AddDropDownList("x270 y375 w100 h120 Choose1", skillModeNames)
        }
    }
    myGui.AddText("x30 y345 w60 h20", "左键:")
    myGui.AddText("x30 y375 w60 h20", "右键:")
}

/**
 * 创建功能键控件
 */
CreateUtilityControls() {
    global myGui, utilityControls, mouseAutoMove, pauseOnClick, compassControl

    myGui.AddText("x30 y405 w60 h20", "翻滚:")
    myGui.AddText("x30 y435 w60 h20", "喝药:")
    myGui.AddText("x30 y465 w60 h20", "强移:")

    utilityControls := {
        dodge: {
            key: myGui.AddText("x90 y405 w35 h20", "空格"),
            enable: myGui.AddCheckbox("x130 y405 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y405 w60 h20", "1000")
        },
        potion: {
            key: myGui.AddHotkey("x90 y435 w35 h20", "q"),
            enable: myGui.AddCheckbox("x130 y435 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y435 w60 h20", "15000")
        },
        forceMove: {
            key: myGui.AddHotkey("x90 y465 w35 h20", "``"),
            enable: myGui.AddCheckbox("x130 y465 w60 h20", "启用"),
            interval: myGui.AddEdit("x200 y465 w60 h20", "50")
        }
    }

    ; 添加鼠标自动移动控件
    mouseAutoMove := {
        enable: myGui.AddCheckbox("x290 y465 w140 h20", "鼠标自动移动"),
        interval: myGui.AddEdit("x430 y465 w40 h20", "1000")
    }
    mouseAutoMove.enable.OnEvent("Click", ToggleMouseAutoMove)

    ; 添加鼠标点击暂停宏控件
    pauseOnClick := {
        enable: myGui.AddCheckbox("x290 y435 w140 h20", "鼠标点击时暂停宏"),
        interval: myGui.AddEdit("x430 y435 w40 h20", "2000")
    }
    pauseOnClick.enable.OnEvent("Click", TogglePauseOnClick)

    ; 添加罗盘专用控件
    compassControl := {
        enable: myGui.AddCheckbox("x290 y405 w100 h20", "罗盘专用"),
        interval: myGui.AddEdit("x400 y405 w70 h20", "65000")
    }
    compassControl.enable.OnEvent("Click", ToggleCompass)
}