; ========== GUI创建（仿D3keyHelper风格） ==========
/**
 * 创建主GUI界面
 */
CreateMainGUI() {
    global myGui, statusText, statusBar, presetTab, presetNames, currentPreset

    ; 创建主窗口
    myGui := Gui("", "暗黑4助手 v2.1")
    myGui.SetFont("s11", "Segoe UI")
    myGui.MarginX := 5
    myGui.MarginY := 10

    ; ========== Tab2预设配置区域（仿d3keyhelper配置1~4风格） ==========
    presetTab := myGui.AddTab2("x5 y5 w630 h555", [presetNames[1], presetNames[2], presetNames[3], presetNames[4]])
    presetTab.OnEvent("Change", OnPresetTabChange)
    presetTab.OnEvent("ContextMenu", OnPresetTabRightClick)
    presetTab.UseTab(0)  ; 后续控件不绑定到特定tab

    ; ========== 按键宏设置 GroupBox ==========
    myGui.AddGroupBox("x15 y38 w610 h260", "按键宏设置")
    myGui.SetFont("s9", "Segoe UI")

    ; 列标题（仿D3表格风格）
    myGui.AddText("x115 y58 w65 center", "快捷键")
    myGui.AddText("x190 y58 w85 center", "策略")
    myGui.AddText("x280 y58 w130 center", "执行间隔（毫秒）")
    myGui.AddText("x420 y58 w80 center", "延迟（毫秒）")
    myGui.AddText("x510 y58 w60 center", "延迟随机")

    ; 创建技能行（4个技能 + 左键 + 右键）
    CreateSkillRows()

    ; ========== 额外设置 GroupBox ==========
    CreateExtraSettings()

    ; ========== 底部状态和控制区域 ==========
    myGui.SetFont("s10", "Segoe UI")
    statusText := myGui.AddText("x25 y505 w200 h20", "状态: 未运行")
    myGui.AddButton("x320 y502 w120 h26", "开始/停止(F1)").OnEvent("Click", ToggleMacro)
    myGui.AddButton("x450 y502 w80 h26", "保存设置").OnEvent("Click", SaveSettings)
    myGui.SetFont("s9", "Segoe UI")
    myGui.AddText("x25 y532 w600 h20", "提示：仅在暗黑破坏神4窗口活动时生效  |  右键配置标签可重命名")
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar

    ; 创建主GUI
    CreateMainGUI()

    ; 添加状态栏
    statusBar := myGui.AddStatusBar(, "就绪")

    ; 先加载设置（在Show之前，避免Tab2内的DropDownList渲染不刷新）
    LoadSettings()

    ; 显示GUI（此时下拉框值已正确设置，首次渲染即为正确状态）
    myGui.Show("w640 h580")

    ; 强制重绘窗口，确保所有控件（尤其是Tab2内的DropDownList）正确显示
    WinRedraw(myGui.Hwnd)

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