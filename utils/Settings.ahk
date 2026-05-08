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
 * 自动保存防抖定时器引用
 */
global autoSaveTimer := 0

/**
 * 调度自动保存（防抖，500ms内多次修改只保存一次）
 */
ScheduleAutoSave(*) {
    global autoSaveTimer
    ; 清除之前的定时器
    if (autoSaveTimer != 0) {
        SetTimer(autoSaveTimer, 0)
    }
    ; 创建新的延迟保存
    autoSaveTimer := AutoSaveCallback
    SetTimer(autoSaveTimer, -500)  ; 500ms后执行一次
}

/**
 * 自动保存回调（实际执行保存）
 */
AutoSaveCallback(*) {
    global autoSaveTimer
    autoSaveTimer := 0
    SaveSettings()
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
        IniWrite(skillControls[i].strategy.Value, file, section, "Skill" i "Strategy")
        IniWrite(skillControls[i].interval.Value, file, section, "Skill" i "Interval")
        IniWrite(skillControls[i].delay.Value, file, section, "Skill" i "Delay")
        IniWrite(skillControls[i].random.Value, file, section, "Skill" i "Random")
        DebugLog("保存技能" i "策略: " skillControls[i].strategy.Value)
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

    ; 保存左键设置（策略式）
    IniWrite(mouseControls.left.strategy.Value, file, section, "LeftClickStrategy")
    IniWrite(mouseControls.left.interval.Value, file, section, "LeftClickInterval")
    IniWrite(mouseControls.left.delay.Value, file, section, "LeftClickDelay")
    IniWrite(mouseControls.left.random.Value, file, section, "LeftClickRandom")
    DebugLog("保存左键策略: " mouseControls.left.strategy.Value)

    ; 保存右键设置（策略式）
    IniWrite(mouseControls.right.strategy.Value, file, section, "RightClickStrategy")
    IniWrite(mouseControls.right.interval.Value, file, section, "RightClickInterval")
    IniWrite(mouseControls.right.delay.Value, file, section, "RightClickDelay")
    IniWrite(mouseControls.right.random.Value, file, section, "RightClickRandom")
    DebugLog("保存右键策略: " mouseControls.right.strategy.Value)

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
 * 读取策略值，兼容旧格式 (Enable+Mode -> Strategy)
 * @param {String} file - 设置文件路径
 * @param {String} section - INI Section
 * @param {String} keyPrefix - 键名前缀（如 "Skill1" 或 "LeftClick"）
 * @param {String} label - 日志标签
 * @returns {Integer} strategy值（1=禁用 / 2=连点 / 3=维持BUFF / 4=按住）
 */
ReadStrategyValue(file, section, keyPrefix, label) {
    global SKILL_MODE_CLICK

    strategy := IniRead(file, section, keyPrefix . "Strategy", "")
    if (strategy != "" && strategy != "ERROR") {
        return Integer(strategy)
    }

    ; 旧格式兼容：从Enable+Mode转换为Strategy
    enabled := Integer(IniRead(file, section, keyPrefix . "Enable", 0))
    mode := Integer(IniRead(file, section, keyPrefix . "Mode", SKILL_MODE_CLICK))
    strategy := enabled ? (mode + 1) : 1  ; 禁用=1，否则mode 1->2, 2->3, 3->4
    DebugLog(label "从旧格式转换: Enable=" enabled ", Mode=" mode " -> Strategy=" strategy)
    return strategy
}

/**
 * 选择策略下拉框，越界时回退到禁用(1)
 */
ChooseStrategy(control, strategy) {
    if (strategy >= 1 && strategy <= 4)
        control.strategy.Choose(strategy)
    else
        control.strategy.Choose(1)
}

/**
 * 加载技能设置
 * @param {String} file - 设置文件路径
 * @param {String} prefix - Section前缀（如 "Preset1_"）
 */
LoadSkillSettings(file, prefix := "") {
    global skillControls
    section := prefix . "Skills"

    Loop 4 {
        try {
            keyPrefix := "Skill" . A_Index
            key := IniRead(file, section, keyPrefix . "Key", A_Index)
            strategy := ReadStrategyValue(file, section, keyPrefix, "技能" . A_Index)
            interval := IniRead(file, section, keyPrefix . "Interval", 300)
            delay := IniRead(file, section, keyPrefix . "Delay", 10)
            random := IniRead(file, section, keyPrefix . "Random", 1)

            skillControls[A_Index].key.Value := key
            ChooseStrategy(skillControls[A_Index], strategy)
            skillControls[A_Index].interval.Value := interval
            skillControls[A_Index].delay.Value := delay
            skillControls[A_Index].random.Value := random

            DebugLog("加载技能" A_Index " - 策略: " strategy ", 间隔: " interval ", 延迟: " delay ", 随机: " random)
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
    global mouseControls, mouseAutoMove, mouseAutoMoveEnabled, pauseOnClick, pauseOnClickEnabled
    section := prefix . "Mouse"

    try {
        ; 加载左键设置（兼容旧格式）
        leftStrategy := ReadStrategyValue(file, section, "LeftClick", "左键")
        mouseControls.left.interval.Value := IniRead(file, section, "LeftClickInterval", 80)
        mouseControls.left.delay.Value := IniRead(file, section, "LeftClickDelay", 10)
        mouseControls.left.random.Value := IniRead(file, section, "LeftClickRandom", 1)
        ChooseStrategy(mouseControls.left, leftStrategy)

        ; 加载右键设置（兼容旧格式）
        rightStrategy := ReadStrategyValue(file, section, "RightClick", "右键")
        mouseControls.right.interval.Value := IniRead(file, section, "RightClickInterval", 300)
        mouseControls.right.delay.Value := IniRead(file, section, "RightClickDelay", 10)
        mouseControls.right.random.Value := IniRead(file, section, "RightClickRandom", 1)
        ChooseStrategy(mouseControls.right, rightStrategy)

        ; 加载自动移动设置
        mouseAutoMove.enable.Value := IniRead(file, section, "MouseAutoMoveEnable", 0)
        mouseAutoMove.interval.Value := IniRead(file, section, "MouseAutoMoveInterval", 1000)
        mouseAutoMoveEnabled := (mouseAutoMove.enable.Value = 1)
        
        ; 加载点击暂停设置
        pauseOnClick.enable.Value := IniRead(file, section, "PauseOnClickEnable", 0)
        pauseOnClick.interval.Value := IniRead(file, section, "PauseOnClickInterval", 3000)
        pauseOnClickEnabled := (pauseOnClick.enable.Value = 1)

        DebugLog("加载鼠标设置 - 左键策略: " leftStrategy ", 右键策略: " rightStrategy)
    } catch as err {
        DebugLog("加载鼠标设置出错: " err.Message)
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