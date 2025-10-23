; ========== 设置管理 ==========
/**
 * 保存设置到INI文件
 */
SaveSettings(*) {
    global statusBar
    settingsFile := A_ScriptDir "\settings.ini"

    try {
        ; 保存各类设置
        SaveSkillSettings(settingsFile)
        SaveMouseSettings(settingsFile)
        SaveUtilitySettings(settingsFile)
        SaveCompassSettings(settingsFile)

        statusBar.Text := "设置已保存"
        DebugLog("所有设置已保存到: " settingsFile)
    } catch as err {
        statusBar.Text := "保存设置失败: " err.Message
        DebugLog("保存设置失败: " err.Message)
    }
}

/**
 * 保存技能设置
 * @param {String} file - 设置文件路径
 */
SaveSkillSettings(file) {
    global skillControls
    section := "Skills"

    for i in [1, 2, 3, 4] {
        IniWrite(skillControls[i].key.Value, file, section, "Skill" i "Key")
        IniWrite(skillControls[i].enable.Value, file, section, "Skill" i "Enable")
        IniWrite(skillControls[i].interval.Value, file, section, "Skill" i "Interval")

        ; 获取下拉框选择的索引并保存
        modeIndex := skillControls[i].mode.Value
        IniWrite(modeIndex, file, section, "Skill" i "Mode")
        DebugLog("保存技能" i "模式: " modeIndex)
    }
}

/**
 * 保存鼠标设置
 * @param {String} file - 设置文件路径
 */
SaveMouseSettings(file) {
    global mouseControls, mouseAutoMove, pauseOnClick
    section := "Mouse"

    ; 保存左键设置
    IniWrite(mouseControls.left.enable.Value, file, section, "LeftClickEnable")
    IniWrite(mouseControls.left.interval.Value, file, section, "LeftClickInterval")
    leftModeIndex := mouseControls.left.mode.Value
    IniWrite(leftModeIndex, file, section, "LeftClickMode")
    DebugLog("保存左键模式: " leftModeIndex)

    ; 保存右键设置
    IniWrite(mouseControls.right.enable.Value, file, section, "RightClickEnable")
    IniWrite(mouseControls.right.interval.Value, file, section, "RightClickInterval")
    rightModeIndex := mouseControls.right.mode.Value
    IniWrite(rightModeIndex, file, section, "RightClickMode")
    DebugLog("保存右键模式: " rightModeIndex)

    ; 保存自动移动设置
    IniWrite(mouseAutoMove.enable.Value, file, section, "MouseAutoMoveEnable")
    IniWrite(mouseAutoMove.interval.Value, file, section, "MouseAutoMoveInterval")
    
    ; 保存点击暂停设置
    IniWrite(pauseOnClick.enable.Value, file, section, "PauseOnClickEnable")
    IniWrite(pauseOnClick.interval.Value, file, section, "PauseOnClickInterval")
}

/**
 * 保存功能键设置
 * @param {String} file - 设置文件路径
 */
SaveUtilitySettings(file) {
    global utilityControls
    section := "Utility"

    IniWrite(utilityControls.dodge.enable.Value, file, section, "DodgeEnable")
    IniWrite(utilityControls.dodge.interval.Value, file, section, "DodgeInterval")
    IniWrite(utilityControls.potion.key.Value, file, section, "PotionKey")
    IniWrite(utilityControls.potion.enable.Value, file, section, "PotionEnable")
    IniWrite(utilityControls.potion.interval.Value, file, section, "PotionInterval")
    IniWrite(utilityControls.forceMove.key.Value, file, section, "ForceMoveKey")
    IniWrite(utilityControls.forceMove.enable.Value, file, section, "ForceMoveEnable")
    IniWrite(utilityControls.forceMove.interval.Value, file, section, "ForceMoveInterval")
}

/**
 * 保存罗盘专用设置
 * @param {String} file - 设置文件路径
 */
SaveCompassSettings(file) {
    global compassControl
    section := "Compass"

    IniWrite(compassControl.enable.Value, file, section, "CompassEnable")
    IniWrite(compassControl.interval.Value, file, section, "CompassInterval")
}

/**
 * 加载设置函数
 */
LoadSettings() {
    settingsFile := A_ScriptDir "\settings.ini"

    if !FileExist(settingsFile) {
        DebugLog("设置文件不存在，使用默认设置")
        return
    }

    try {
        ; 加载各类设置
        LoadSkillSettings(settingsFile)
        LoadMouseSettings(settingsFile)
        LoadUtilitySettings(settingsFile)
        LoadCompassSettings(settingsFile)

        DebugLog("所有设置已从文件加载: " settingsFile)
    } catch as err {
        DebugLog("加载设置出错: " err.Message)
    }
}

/**
 * 加载技能设置
 * @param {String} file - 设置文件路径
 */
LoadSkillSettings(file) {
    global skillControls, SKILL_MODE_CLICK

    Loop 4 {
        try {
            key := IniRead(file, "Skills", "Skill" A_Index "Key", A_Index)
            enabled := IniRead(file, "Skills", "Skill" A_Index "Enable", 1)
            interval := IniRead(file, "Skills", "Skill" A_Index "Interval", 300)
            mode := Integer(IniRead(file, "Skills", "Skill" A_Index "Mode", SKILL_MODE_CLICK))

            skillControls[A_Index].key.Value := key
            skillControls[A_Index].enable.Value := enabled
            skillControls[A_Index].interval.Value := interval

            ; 设置模式下拉框
            try {
                DebugLog("尝试设置技能" A_Index "模式为: " mode)
                if (mode >= 1 && mode <= 3) {
                    ; 直接设置Text属性而不是使用Choose方法
                    if (mode == 1)
                        skillControls[A_Index].mode.Text := "连点"
                    else if (mode == 2)
                        skillControls[A_Index].mode.Text := "维持BUFF"
                    else if (mode == 3)
                        skillControls[A_Index].mode.Text := "按住"

                    DebugLog("成功设置技能" A_Index "模式为: " mode)
                } else {
                    skillControls[A_Index].mode.Text := "连点"
                    DebugLog("技能" A_Index "模式值无效: " mode "，使用默认连点模式")
                }
            } catch as err {
                skillControls[A_Index].mode.Text := "连点"
                DebugLog("设置技能" A_Index "模式出错: " err.Message "，使用默认连点模式")
            }
        } catch as err {
            DebugLog("加载技能" A_Index "设置出错: " err.Message)
        }
    }
}

/**
 * 加载鼠标设置
 * @param {String} file - 设置文件路径
 */
LoadMouseSettings(file) {
    global mouseControls, mouseAutoMove, mouseAutoMoveEnabled, pauseOnClick, pauseOnClickEnabled, SKILL_MODE_CLICK

    try {
        ; 加载左键设置
        mouseControls.left.enable.Value := IniRead(file, "Mouse", "LeftClickEnable", 1)
        mouseControls.left.interval.Value := IniRead(file, "Mouse", "LeftClickInterval", 80)
        leftMode := Integer(IniRead(file, "Mouse", "LeftClickMode", SKILL_MODE_CLICK))

        ; 加载右键设置
        mouseControls.right.enable.Value := IniRead(file, "Mouse", "RightClickEnable", 0)
        mouseControls.right.interval.Value := IniRead(file, "Mouse", "RightClickInterval", 300)
        rightMode := Integer(IniRead(file, "Mouse", "RightClickMode", SKILL_MODE_CLICK))

        ; 加载自动移动设置
        mouseAutoMove.enable.Value := IniRead(file, "Mouse", "MouseAutoMoveEnable", 0)
        mouseAutoMove.interval.Value := IniRead(file, "Mouse", "MouseAutoMoveInterval", 1000)
        mouseAutoMoveEnabled := (mouseAutoMove.enable.Value = 1)
        
        ; 加载点击暂停设置
        pauseOnClick.enable.Value := IniRead(file, "Mouse", "PauseOnClickEnable", 0)
        pauseOnClick.interval.Value := IniRead(file, "Mouse", "PauseOnClickInterval", 3000)
        pauseOnClickEnabled := (pauseOnClick.enable.Value = 1)

        ; 设置左键模式下拉框
        SetMouseModeDropdown(mouseControls.left.mode, leftMode, "左键")

        ; 设置右键模式下拉框
        SetMouseModeDropdown(mouseControls.right.mode, rightMode, "右键")

        DebugLog("加载鼠标设置 - 自动移动状态: " . (mouseAutoMoveEnabled ? "启用" : "禁用"))
    } catch as err {
        DebugLog("加载鼠标设置出错: " err.Message)
    }
}

/**
 * 设置鼠标模式下拉框
 * @param {Object} dropdown - 下拉框控件
 * @param {Integer} mode - 模式值
 * @param {String} name - 按键名称
 */
SetMouseModeDropdown(dropdown, mode, name) {
    try {
        DebugLog("尝试设置" name "模式为: " mode)
        if (mode >= 1 && mode <= 3) {
            ; 直接设置Text属性而不是使用Choose方法
            if (mode == 1)
                dropdown.Text := "连点"
            else if (mode == 2)
                dropdown.Text := "维持BUFF"
            else if (mode == 3)
                dropdown.Text := "按住"

            DebugLog("成功设置" name "模式为: " mode)
        } else {
            dropdown.Text := "连点"
            DebugLog(name "模式值无效: " mode "，使用默认连点模式")
        }
    } catch as err {
        dropdown.Text := "连点"
        DebugLog("设置" name "模式出错: " err.Message "，使用默认连点模式")
    }
}

/**
 * 加载功能键设置
 * @param {String} file - 设置文件路径
 */
LoadUtilitySettings(file) {
    global utilityControls

    try {
        utilityControls.dodge.enable.Value := IniRead(file, "Utility", "DodgeEnable", 0)
        utilityControls.dodge.interval.Value := IniRead(file, "Utility", "DodgeInterval", 1000)

        utilityControls.potion.key.Value := IniRead(file, "Utility", "PotionKey", "q")
        utilityControls.potion.enable.Value := IniRead(file, "Utility", "PotionEnable", 0)
        utilityControls.potion.interval.Value := IniRead(file, "Utility", "PotionInterval", 15000)

        utilityControls.forceMove.key.Value := IniRead(file, "Utility", "ForceMoveKey", "``")
        utilityControls.forceMove.enable.Value := IniRead(file, "Utility", "ForceMoveEnable", 0)
        utilityControls.forceMove.interval.Value := IniRead(file, "Utility", "ForceMoveInterval", 50)
    } catch as err {
        DebugLog("加载功能键设置出错: " err.Message)
    }
}

/**
 * 加载罗盘专用设置
 * @param {String} file - 设置文件路径
 */
LoadCompassSettings(file) {
    global compassControl, compassEnabled

    try {
        compassControl.enable.Value := IniRead(file, "Compass", "CompassEnable", 0)
        compassControl.interval.Value := IniRead(file, "Compass", "CompassInterval", 65000)
        compassEnabled := (compassControl.enable.Value = 1)

        DebugLog("加载罗盘专用设置 - 状态: " . (compassEnabled ? "启用" : "禁用") . ", 间隔: " . compassControl.interval.Value)
    } catch as err {
        DebugLog("加载罗盘专用设置出错: " err.Message)
    }
}