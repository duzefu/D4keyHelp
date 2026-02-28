; ========== GUI创建 ==========
/**
 * 创建主GUI界面
 */
CreateMainGUI() {
    global myGui, statusText, statusBar, presetTab, presetNames, currentPreset

    ; 创建主窗口
    myGui := Gui("", "暗黑4助手 v2.1")
    myGui.BackColor := "FFFFFF"
    myGui.SetFont("s10", "Microsoft YaHei UI")

    ; ========== Tab2预设配置区域（仿d3keyhelper配置1~4风格） ==========
    ; 注意：必须使用Tab2而非Tab3，因为Tab3会裁剪(clip)同级控件，
    ; 导致UseTab(0)添加的控件无法接收鼠标点击事件
    presetTab := myGui.AddTab2("x5 y5 w470 h560", [presetNames[1], presetNames[2], presetNames[3], presetNames[4]])
    presetTab.OnEvent("Change", OnPresetTabChange)
    presetTab.OnEvent("ContextMenu", OnPresetTabRightClick)
    presetTab.UseTab(0)  ; 后续控件不绑定到特定tab，视觉上显示在tab内容区

    ; ========== 状态区域 ==========
    myGui.AddGroupBox("x15 y38 w450 h110", "状态")
    statusText := myGui.AddText("x35 y60 w200 h20", "状态: 未运行")
    myGui.AddButton("x35 y88 w120 h30", "开始/停止(F1)").OnEvent("Click", ToggleMacro)
    myGui.AddText("x35 y122 w300 h20", "提示：仅在暗黑破坏神4窗口活动时生效")

    ; ========== 技能设置区域 ==========
    myGui.AddGroupBox("x15 y155 w450 h360", "键设置")

    ; 添加Shift键勾选框
    myGui.AddCheckbox("x35 y180 w100 h20", "按住Shift").OnEvent("Click", ToggleShift)

    ; 添加列标题
    myGui.AddText("x35 y208 w60 h20", "按键")
    myGui.AddText("x135 y208 w60 h20", "启用")
    myGui.AddText("x205 y208 w120 h20", "间隔(毫秒)")
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar

    ; 创建主GUI
    CreateMainGUI()

    ; 创建各种控件
    CreateSkillControls()
    CreateMouseControls()
    CreateUtilityControls()

    ; 添加保存按钮
    myGui.AddButton("x35 y525 w100 h30", "保存设置").OnEvent("Click", SaveSettings)

    ; 添加状态栏
    statusBar := myGui.AddStatusBar(, "就绪")

    ; 显示GUI
    myGui.Show("w480 h595")

    ; 加载设置
    LoadSettings()

    ; 设置窗口事件处理 - 退出时自动保存
    myGui.OnEvent("Close", OnGuiClose)
    myGui.OnEvent("Escape", OnGuiClose)
}

/**
 * GUI关闭事件处理 - 退出前自动保存设置
 */
OnGuiClose(*) {
    try {
        SaveSettings()
        DebugLog("退出前已自动保存设置")
    } catch as err {
        DebugLog("退出前保存设置失败: " err.Message)
    }
    ExitApp()
}