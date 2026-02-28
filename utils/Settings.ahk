; ========== 设置管理 ==========

/**
 * 获取当前预设的Section前缀
 * @param {Integer} presetIndex - 预设索引 (1-4)，默认使用当前预设
 * @returns {String} Section前缀，如 "Preset1_"
 */
GetPresetPrefix(presetIndex := 0) {
    global currentPreset
    if (presetIndex = 0)
        presetIndex := currentPreset
    return "Preset" . presetIndex . "_"
}

/**
 * 保存设置到INI文件（保存当前预设）
 */
SaveSettings(*) {
    global statusBar, currentPreset, presetNames
    settingsFile := A_ScriptDir "\settings.ini"

    try {
        prefix := GetPresetPrefix()

        ; 保存预设元信息
        SavePresetMeta(settingsFile)

        ; 保存各类设置（带预设前缀）
        SaveSkillSettings(settingsFile, prefix)
        SaveMouseSettings(settingsFile, prefix)
        SaveUtilitySettings(settingsFile, prefix)
        SaveCompassSettings(settingsFile, prefix)

        statusBar.Text := "设置已保存 [" . presetNames[currentPreset] . "]"
        DebugLog("所有设置已保存到: " settingsFile " [预设" . currentPreset . ": " . presetNames[currentPreset] . "]")
    } catch as err {
        statusBar.Text := "保存设置失败: " err.Message
        DebugLog("保存设置失败: " err.Message)
    }
}

/**
 * 保存预设元信息
 * @param {String} file - 设置文件路径
 */
SavePresetMeta(file) {
    global currentPreset, presetNames

    IniWrite(currentPreset, file, "Presets", "CurrentPreset")
    Loop 4 {
        IniWrite(presetNames[A_Index], file, "Presets", "Preset" . A_Index . "Name")
    }
    DebugLog("预设元信息已保存，当前预设: " . currentPreset)
}

/**
 * 加载预设元信息
 * @param {String} file - 设置文件路径
 * @returns {Boolean} 是否成功加载（false表示旧格式需要迁移）
 */
LoadPresetMeta(file) {
    global currentPreset, presetNames

    try {
        ; 尝试读取预设元信息，如果不存在说明是旧格式
        currentPreset := Integer(IniRead(file, "Presets", "CurrentPreset", 0))
        if (currentPreset = 0) {
            return false  ; 旧格式，需要迁移
        }

        ; 确保预设索引在有效范围内
        if (currentPreset < 1 || currentPreset > 4)
            currentPreset := 1

        Loop 4 {
            presetNames[A_Index] := IniRead(file, "Presets", "Preset" . A_Index . "Name", "配置" . A_Index)
        }
        DebugLog("预设元信息已加载，当前预设: " . currentPreset . " - " . presetNames[currentPreset])
        return true
    } catch as err {
        DebugLog("加载预设元信息出错: " err.Message)
        return false
    }
}

/**
 * 迁移旧格式settings.ini到新预设格式
 * @param {String} file - 设置文件路径
 */
MigrateOldSettings(file) {
    global currentPreset, presetNames

    DebugLog("检测到旧格式设置文件，开始迁移到预设格式...")

    ; 旧Section名到新Section名的映射
    oldSections := ["Skills", "Mouse", "Utility", "Compass"]

    for sectionName in oldSections {
        newSection := "Preset1_" . sectionName
        try {
            ; 读取旧Section的所有键值对
            sectionContent := IniRead(file, sectionName)
            if (sectionContent != "") {
                ; 逐行解析并写入新Section
                Loop Parse, sectionContent, "`n", "`r"
                {
                    parts := StrSplit(A_LoopField, "=",, 2)
                    if (parts.Length >= 2) {
                        IniWrite(parts[2], file, newSection, parts[1])
                    }
                }
                DebugLog("迁移Section: " . sectionName . " -> " . newSection)
            }
        } catch as err {
            DebugLog("迁移Section " . sectionName . " 出错: " . err.Message)
        }
    }

    ; 设置默认预设元信息
    currentPreset := 1
    presetNames := ["配置1", "配置2", "配置3", "配置4"]
    SavePresetMeta(file)

    DebugLog("旧设置迁移完成，已设置为配置1")
}

/**
 * 切换预设
 * @param {Integer} targetIndex - 目标预设索引 (1-4)
 */
SwitchPreset(targetIndex) {
    global currentPreset, statusBar, presetNames, isRunning

    ; 如果宏正在运行，阻止切换
    if (isRunning) {
        statusBar.Text := "请先停止宏再切换预设"
        DebugLog("宏运行中，阻止切换预设")
        ; 恢复Tab到当前预设
        UpdatePresetTabs()
        return
    }

    if (targetIndex = currentPreset)
        return

    settingsFile := A_ScriptDir "\settings.ini"

    try {
        ; 先保存当前预设
        prefix := GetPresetPrefix()
        SaveSkillSettings(settingsFile, prefix)
        SaveMouseSettings(settingsFile, prefix)
        SaveUtilitySettings(settingsFile, prefix)
        SaveCompassSettings(settingsFile, prefix)
        DebugLog("切换前保存预设" . currentPreset . "完成")

        ; 切换到目标预设
        currentPreset := targetIndex
        SavePresetMeta(settingsFile)

        ; 加载目标预设
        prefix := GetPresetPrefix()
        LoadSkillSettings(settingsFile, prefix)
        LoadMouseSettings(settingsFile, prefix)
        LoadUtilitySettings(settingsFile, prefix)
        LoadCompassSettings(settingsFile, prefix)

        statusBar.Text := "已切换到: " . presetNames[currentPreset]
        DebugLog("已切换到预设" . currentPreset . ": " . presetNames[currentPreset])

        ; 更新Tab显示
        UpdatePresetTabs()
    } catch as err {
        statusBar.Text := "切换预设失败: " . err.Message
        DebugLog("切换预设失败: " . err.Message)
    }
}

/**
 * Tab切换事件处理（仿d3keyhelper配置Tab风格）
 * @param {Object} ctrl - Tab控件
 */
OnPresetTabChange(ctrl, *) {
    global currentPreset, suppressTabChange, isRunning, statusBar

    if (suppressTabChange)
        return

    newIndex := ctrl.Value
    if (newIndex = currentPreset || newIndex < 1)
        return

    if (isRunning) {
        ; 宏运行中阻止切换，恢复到当前Tab
        suppressTabChange := true
        ctrl.Choose(currentPreset)
        suppressTabChange := false
        statusBar.Text := "请先停止宏再切换配置"
        DebugLog("宏运行中，阻止切换配置Tab")
        return
    }

    SwitchPreset(newIndex)
}

/**
 * Tab右键事件处理 - 重命名当前配置
 * @param {Object} ctrl - Tab控件
 */
OnPresetTabRightClick(ctrl, *) {
    global currentPreset
    RenamePreset(currentPreset)
}

/**
 * 重命名指定预设
 * @param {Integer} index - 预设索引 (1-4)
 */
RenamePreset(index, *) {
    global currentPreset, presetNames, statusBar

    ; 弹出输入框
    result := InputBox("请输入新的配置名称:", "重命名配置" . index, "w300 h120", presetNames[index])

    if (result.Result = "Cancel" || result.Value = "")
        return

    newName := result.Value
    presetNames[index] := newName

    ; 保存元信息
    settingsFile := A_ScriptDir "\settings.ini"
    SavePresetMeta(settingsFile)

    ; 更新Tab显示
    UpdatePresetTabs()

    statusBar.Text := "配置" . index . "已重命名为: " . newName
    DebugLog("配置" . index . "重命名为: " . newName)
}

/**
 * 更新预设Tab显示（重建Tab标签名称并选中当前配置）
 */
UpdatePresetTabs() {
    global presetTab, presetNames, currentPreset, suppressTabChange

    if (presetTab = "")
        return

    suppressTabChange := true
    try {
        ; 删除所有Tab并重新添加（用于更新Tab名称）
        presetTab.Delete()
        presetTab.Add([presetNames[1], presetNames[2], presetNames[3], presetNames[4]])
        presetTab.Choose(currentPreset)
    }
    suppressTabChange := false
}

/**
 * 保存技能设置
 * @param {String} file - 设置文件路径
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
SaveSkillSettings(file, prefix := "") {
    global skillControls
    section := prefix . "Skills"

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
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
SaveMouseSettings(file, prefix := "") {
    global mouseControls, mouseAutoMove, pauseOnClick
    section := prefix . "Mouse"

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
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
SaveUtilitySettings(file, prefix := "") {
    global utilityControls
    section := prefix . "Utility"

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
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
SaveCompassSettings(file, prefix := "") {
    global compassControl
    section := prefix . "Compass"

    IniWrite(compassControl.enable.Value, file, section, "CompassEnable")
    IniWrite(compassControl.interval.Value, file, section, "CompassInterval")
}

/**
 * 加载设置函数
 */
LoadSettings() {
    global currentPreset, presetNames
    settingsFile := A_ScriptDir "\settings.ini"

    if !FileExist(settingsFile) {
        DebugLog("设置文件不存在，使用默认设置")
        return
    }

    try {
        ; 先加载预设元信息
        if !LoadPresetMeta(settingsFile) {
            ; 旧格式，执行迁移
            MigrateOldSettings(settingsFile)
        }

        ; 更新预设Tab显示
        UpdatePresetTabs()

        ; 根据当前预设加载各类设置
        prefix := GetPresetPrefix()
        LoadSkillSettings(settingsFile, prefix)
        LoadMouseSettings(settingsFile, prefix)
        LoadUtilitySettings(settingsFile, prefix)
        LoadCompassSettings(settingsFile, prefix)

        DebugLog("所有设置已从文件加载: " settingsFile " [预设" . currentPreset . ": " . presetNames[currentPreset] . "]")
    } catch as err {
        DebugLog("加载设置出错: " err.Message)
    }
}

/**
 * 加载技能设置
 * @param {String} file - 设置文件路径
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
LoadSkillSettings(file, prefix := "") {
    global skillControls, SKILL_MODE_CLICK
    section := prefix . "Skills"

    Loop 4 {
        try {
            key := IniRead(file, section, "Skill" A_Index "Key", A_Index)
            enabled := IniRead(file, section, "Skill" A_Index "Enable", 1)
            interval := IniRead(file, section, "Skill" A_Index "Interval", 300)
            mode := Integer(IniRead(file, section, "Skill" A_Index "Mode", SKILL_MODE_CLICK))

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
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
LoadMouseSettings(file, prefix := "") {
    global mouseControls, mouseAutoMove, mouseAutoMoveEnabled, pauseOnClick, pauseOnClickEnabled, SKILL_MODE_CLICK
    section := prefix . "Mouse"

    try {
        ; 加载左键设置
        mouseControls.left.enable.Value := IniRead(file, section, "LeftClickEnable", 1)
        mouseControls.left.interval.Value := IniRead(file, section, "LeftClickInterval", 80)
        leftMode := Integer(IniRead(file, section, "LeftClickMode", SKILL_MODE_CLICK))

        ; 加载右键设置
        mouseControls.right.enable.Value := IniRead(file, section, "RightClickEnable", 0)
        mouseControls.right.interval.Value := IniRead(file, section, "RightClickInterval", 300)
        rightMode := Integer(IniRead(file, section, "RightClickMode", SKILL_MODE_CLICK))

        ; 加载自动移动设置
        mouseAutoMove.enable.Value := IniRead(file, section, "MouseAutoMoveEnable", 0)
        mouseAutoMove.interval.Value := IniRead(file, section, "MouseAutoMoveInterval", 1000)
        mouseAutoMoveEnabled := (mouseAutoMove.enable.Value = 1)
        
        ; 加载点击暂停设置
        pauseOnClick.enable.Value := IniRead(file, section, "PauseOnClickEnable", 0)
        pauseOnClick.interval.Value := IniRead(file, section, "PauseOnClickInterval", 3000)
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
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
LoadUtilitySettings(file, prefix := "") {
    global utilityControls
    section := prefix . "Utility"

    try {
        utilityControls.dodge.enable.Value := IniRead(file, section, "DodgeEnable", 0)
        utilityControls.dodge.interval.Value := IniRead(file, section, "DodgeInterval", 1000)

        utilityControls.potion.key.Value := IniRead(file, section, "PotionKey", "q")
        utilityControls.potion.enable.Value := IniRead(file, section, "PotionEnable", 0)
        utilityControls.potion.interval.Value := IniRead(file, section, "PotionInterval", 15000)

        utilityControls.forceMove.key.Value := IniRead(file, section, "ForceMoveKey", "``")
        utilityControls.forceMove.enable.Value := IniRead(file, section, "ForceMoveEnable", 0)
        utilityControls.forceMove.interval.Value := IniRead(file, section, "ForceMoveInterval", 50)
    } catch as err {
        DebugLog("加载功能键设置出错: " err.Message)
    }
}

/**
 * 加载罗盘专用设置
 * @param {String} file - 设置文件路径
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
LoadCompassSettings(file, prefix := "") {
    global compassControl, compassEnabled
    section := prefix . "Compass"

    try {
        compassControl.enable.Value := IniRead(file, section, "CompassEnable", 0)
        compassControl.interval.Value := IniRead(file, section, "CompassInterval", 65000)
        compassEnabled := (compassControl.enable.Value = 1)

        DebugLog("加载罗盘专用设置 - 状态: " . (compassEnabled ? "启用" : "禁用") . ", 间隔: " . compassControl.interval.Value)
    } catch as err {
        DebugLog("加载罗盘专用设置出错: " err.Message)
    }
}